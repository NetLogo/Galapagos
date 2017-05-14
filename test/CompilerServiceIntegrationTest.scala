import scala.concurrent.Future

import
  play.api.{ Application, inject, libs, mvc, test },
    inject.guice.GuiceApplicationBuilder,
    libs.{ iteratee, json },
      iteratee.Iteratee,
      json.{ JsObject, Json, JsString },
    mvc.{ EssentialAction, Result },
    test.{ FakeRequest, Helpers },
      Helpers.{ await, call, contentAsString, defaultAwaitTimeout, writeableOf_AnyContentAsFormUrlEncoded }

import org.scalatestplus.play.PlaySpec
import org.scalatestplus.play.guice.GuiceOneAppPerSuite

import akka.stream.Materializer

class CompilerServiceIntegrationTest extends PlaySpec with GuiceOneAppPerSuite {

  import CompilerServiceHelpers._
  import scala.concurrent.ExecutionContext.Implicits.global

  override implicit lazy val app: Application =
    new GuiceApplicationBuilder()
      .configure("play.akka.shutdown-timeout" -> "2s")
      .configure("akka.log-dead-letters"      -> 0)
      .build

  implicit lazy val materializer: Materializer = app.materializer

  val longTimeout = akka.util.Timeout(60, java.util.concurrent.TimeUnit.SECONDS)

  "CompilerService controller" must {
    Map(
      "wolf sheep"          -> wolfSheep,
      "custom turtle shape" -> breedProcedures,
      "custom link shape"   -> linkBreeds
    ).foreach {
      case (name, modelText) =>
        s"preserve $name model information" in {
          await {
            makeRequest("POST", "/compile-nlogo", "model" -> modelText).flatMap {
              case (firstResult, firstResultBody) =>
                val fields = sanitizedJsonModel(firstResultBody, "turtleShapes", "linkShapes") - "model"
                firstResult.header.status  mustEqual 200
                makeRequest("POST", "/compile-code", fields.toSeq: _*).map {
                  case (secondResult, secondResultBody) =>
                    secondResult.header.status mustEqual 200
                    secondResultBody mustEqual firstResultBody
                }
            }
          }(longTimeout)
        }
    }
  }

  private def makeRequest(method: String, path: String, formBody: (String, String)*): Future[(Result, String)] = {
    val req = FakeRequest(method, path).withFormUrlEncodedBody(formBody: _*)
    val (_, handler) = app.requestHandler.handlerForRequest(req)
    call(handler.asInstanceOf[EssentialAction], req).map(res => (res, contentAsString(Future(res))))
  }

  private def sanitizedJsonModel(rawJson: String, modelVars: String*): Map[String, String] = {
    val jobject@JsObject(jsonFields) = Json.parse(rawJson)

    val JsString(modelJs) = (jobject \ "model" \ "result").get

    val fields = jsonFields.toMap.map {
      case ("widgets", JsString(s)) => ("widgets", Json.prettyPrint(Json.parse(s.replaceAll(":function\\(\\) \\{.*\\},\"", ":null,\""))))
      case (k,         JsString(s)) => (k,         s)
      case (k,         j)           => (k,         Json.prettyPrint(j))
    }

    val jsVarRegex = """(?m)^var (\w+) = (.*);$""".r

    val declaredVars = jsVarRegex.findAllMatchIn(modelJs).map {
      case jsVarRegex(varName, varValue) => varName -> varValue
    }

    fields ++ declaredVars.filter(t => modelVars.contains(t._1))
  }
}

import
  scalaz.{ Scalaz, NonEmptyList },
    Scalaz.ToValidationOps

import
  org.nlogo.{ core, parse, tortoise },
    core.{ CompilerException, model, Model },
      model.ModelReader,
    parse.CompilerUtilities,
    tortoise.CompiledModel

import
  org.scalatestplus.play.PlaySpec

import
  play.api.libs.json.Json

import
  models.{ compile, json, Util },
    compile.{ CompileResponse, IDedValuesMap, IDedValuesSeq },
    json.Writers.compileResponseWrites,
    Util.usingSource

class CompilerServiceTest extends PlaySpec {

  import CompilerServiceHelpers._

  private implicit def map2IdedValues[T](map: Map[String, T]): IDedValuesMap[T] = IDedValuesMap(map)
  private implicit def seq2IdedValues[T](seq: Seq[T]):         IDedValuesSeq[T] = IDedValuesSeq(seq)

  private val CommandsKey  = "commands"
  private val InfoKey      = "info"
  private val ModelKey     = "model"
  private val ReportersKey = "reporters"

  "CompilerService" must {
    "compile nlogo contents" in {
      val result = CompileResponse.fromModel(wsModelV, Seq(), Seq())
      result.model mustBe wsModel.compiledCode.successNel[CompilerException]
    }

    "compile commands and reporters in order" in {
      val commands  = Seq("crt 1", "ca")
      val reporters = Seq("count turtles", "5 + 10", "4 + 2")

      val result            = CompileResponse.fromModel(wsModelV, commands, reporters)
      val compiledCommands  = commands  map { s => wsModel.compileCommand(s) }
      val compiledReporters = reporters map { s => wsModel.compileReporter(s) }

      result.commands  mustBe IDedValuesSeq(compiledCommands)
      result.reporters mustBe IDedValuesSeq(compiledReporters)
    }

    "compile commands and reporters, preserving ids" in {
      val commands  = Map("one" -> "crt 1", "two" -> "ca")
      val reporters = Map("one" -> "count turtles", "two" -> "5 + 10", "three" -> "4 + 2")

      val result            = CompileResponse.fromModel(wsModelV, commands, reporters)
      val compiledCommands  = commands.mapValues  { s => wsModel.compileCommand(s) }
      val compiledReporters = reporters.mapValues { s => wsModel.compileReporter(s) }

      result.commands  mustBe IDedValuesMap(compiledCommands)
      result.reporters mustBe IDedValuesMap(compiledReporters)
    }

    "gracefully handle errors in commands and reporters" in {
      // Formatted to make it easy to see expected success of each code string. BCH 8/23/2014
      val commands  = Map(
        "crt 1"         -> true,
        "idontexit 4 5" -> false,
        "4 + 5"         -> false,
        "setup"         -> true
      )
      val reporters = Map(
        "count turtles" -> true,
        "crt 1"         -> false,
        "idontexit 4 5" -> false,
        "grass"         -> true
      )
      val result    = CompileResponse.fromModel(wsModelV,
                                                commands.keys.toSeq,
                                                reporters.keys.toSeq)

      result.commands  mapValues { _.isSuccess } mustBe IDedValuesSeq(commands.values.toSeq)
      result.reporters mapValues { _.isSuccess } mustBe IDedValuesSeq(reporters.values.toSeq)
    }

    "convert response objects to JSON" in {
      val allGood = CompileResponse("model test".successNel[CompilerException],
                                    "some info",
                                    "some code",
                                    List(),
                                    Seq("command".successNel[CompilerException]),
                                    Seq("reporter".successNel[CompilerException]))
      val allGoodJson = Json.toJson(allGood)
      (allGoodJson \ ModelKey \ "success").as[Boolean] mustBe true
      (allGoodJson \ ModelKey \ "result").as[String] mustBe allGood.model.getOrElse(
        fail("Bad test: CompileResult was supposed to contain a String")
      )
      ((allGoodJson \ CommandsKey)(0) \ "success").as[Boolean] mustBe true
      (allGoodJson \ InfoKey).as[String] mustBe "some info"
      ((allGoodJson \ CommandsKey)(0) \ "result").as[String] mustBe "command"
      ((allGoodJson \ ReportersKey)(0) \ "success").as[Boolean] mustBe true
      ((allGoodJson \ ReportersKey)(0) \ "result").as[String] mustBe "reporter"

      val allGoodMap = CompileResponse("model test".successNel[CompilerException],
                                       "some info",
                                       "some code",
                                       List(),
                                       Map("id" -> "commands test".successNel[CompilerException]),
                                       Seq())
      val allGoodMapJson = Json.toJson(allGoodMap)
      (allGoodMapJson \ CommandsKey \ "id" \ "success").as[Boolean] mustBe true

      val notGood = CompileResponse(new CompilerException("error", 0, 10, "").failureNel[String],
                                    "info",
                                    "code",
                                    List(),
                                    Seq(),
                                    Seq())
      val notGoodJson = Json.toJson(notGood)
      (notGoodJson \ ModelKey \ "success").as[Boolean] mustBe false
      ((notGoodJson \ ModelKey \ "result")(0) \ "message").as[String] mustBe notGood.model.fold(
        _.head.getMessage,
        success => fail("Bad test: CompileResult was supposed to contain a CompilerException")
      )
    }

    "convert models to nlogo" in {
      val nlogo = CompileResponse.exportNlogo(wsModel.successNel)
        .getOrElse(throw new Exception("Exporting should have succeeded, but failed"))
      openModel(nlogo) mustBe wsModel.model
    }
  }

  val wsModel = {
    val modelShouldHaveCompiled = (failures: NonEmptyList[CompilerException]) =>
      s"""|Model should have compiled but failed with the following messages:
          |${failures.stream.mkString("\n")}""".stripMargin
    wsModelV valueOr { e => fail(modelShouldHaveCompiled(e)) }
  }
}

object CompilerServiceHelpers {
  private def modelText(modelName: String): String =
    usingSource(_.fromFile(s"public/modelslib/$modelName"))(_.mkString)

  val breedProcedures = modelText("Code Examples/Breed Procedures Example.nlogo")

  val linkBreeds = modelText("Code Examples/Link Breeds Example.nlogo")

  val wolfSheep = modelText("Sample Models/Biology/Wolf Sheep Predation.nlogo")

  val wsModelV = CompiledModel.fromModel(openModel(wolfSheep))

  def openModel(model: String): Model =
    ModelReader.parseModel(model, CompilerUtilities, Map())

  val widgetModel = CompiledModel.fromModel(openModel(modelText("../demomodels/All Widgets.nlogo")))
}

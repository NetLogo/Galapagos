package controllers

import
  scala.io.Source

import
  scalaz.{ Scalaz, NonEmptyList },
    Scalaz.ToValidationOps

import
  org.nlogo.{ api, tortoise },
    api.CompilerException,
    tortoise.CompiledModel

import
  org.scalatestplus.play.PlaySpec

import
  play.api.{libs, test, http},
    libs.json.{Json, JsSuccess},
    test.{FakeRequest, Helpers},
    http.Status

import
  CompilerService._

class CompilerServiceTest extends PlaySpec {

  "CompilerService" must {
    "compile nlogo contents" in {
      val result = CompilerService.compile(CompiledModel.fromNlogoContents(wolfSheep), Seq(), Seq())
      result.model mustBe wsModel.compiledCode.successNel[CompilerException]
    }

    "compile commands and reporters in order" in {
      val commands  = Seq("crt 1", "ca")
      val reporters = Seq("count turtles", "5 + 10", "4 + 2")

      val result            = CompilerService.compile(CompiledModel.fromNlogoContents(wolfSheep), commands, reporters)
      val compiledCommands  = commands  map { s => wsModel.compileCommand(s) }
      val compiledReporters = reporters map { s => wsModel.compileReporter(s) }

      result.commands  mustBe IDedValuesSeq(compiledCommands)
      result.reporters mustBe IDedValuesSeq(compiledReporters)
    }

    "compile commands and reporters, preserving ids" in {
      val commands  = Map("one" -> "crt 1", "two" -> "ca")
      val reporters = Map("one" -> "count turtles", "two" -> "5 + 10", "three" -> "4 + 2")

      val result            = CompilerService.compile(CompiledModel.fromNlogoContents(wolfSheep), commands, reporters)
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
      val result    = CompilerService.compile(CompiledModel.fromNlogoContents(wolfSheep),
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
      (allGoodJson \ modelKey \ "success").as[Boolean] mustBe true
      (allGoodJson \ modelKey \ "result").as[String] mustBe allGood.model.getOrElse(
        fail("Bad test: CompileResult was supposed to contain a String")
      )
      ((allGoodJson \ commandsKey)(0) \ "success").as[Boolean] mustBe true
      (allGoodJson \ infoKey).as[String] mustBe "some info"
      ((allGoodJson \ commandsKey)(0) \ "result").as[String] mustBe "command"
      ((allGoodJson \ reportersKey)(0) \ "success").as[Boolean] mustBe true
      ((allGoodJson \ reportersKey)(0) \ "result").as[String] mustBe "reporter"

      val allGoodMap = CompileResponse("model test".successNel[CompilerException],
                                       "some info",
                                       "some code",
                                       List(),
                                       Map("id" -> "commands test".successNel),
                                       Seq())
      val allGoodMapJson = Json.toJson(allGoodMap)
      (allGoodMapJson \ commandsKey \ "id" \ "success").as[Boolean] mustBe true

      val notGood = CompileResponse(new CompilerException("error", 0, 10, "").failureNel[String],
                                    "info",
                                    "code",
                                    List(),
                                    Seq(),
                                    Seq())
      val notGoodJson = Json.toJson(notGood)
      (notGoodJson \ modelKey \ "success").as[Boolean] mustBe false
      ((notGoodJson \ modelKey \ "result")(0) \ "message").as[String] mustBe notGood.model.fold(
        _.head.getMessage,
        success => fail("Bad test: CompileResult was supposed to contain a CompilerException")
      )
    }

    "compile and serialize widgets without error" in {
      val modelResponse = CompilerService.compile(widgetModel, Seq(), Seq())
      val widgetString = Json.toJson(modelResponse.widgets).toString
      widgetModel.fold(
        errs  => fail(errs.stream.mkString("\n")),
        model => parseWidgets(widgetString).fold(
          errs    => fail(errs.stream.mkString("\n")),
          // The mkString("\n")s make failures easier to read.
          widgets => widgets.mkString("\n") mustBe model.model.widgets.mkString("\n")
        )
      )
    }
  }

  private val wolfSheep = Source.fromFile("public/modelslib/Sample Models/Biology/Wolf Sheep Predation.nlogo").mkString
  private val wsModel = {
    val modelShouldHaveCompiled = (failures: NonEmptyList[CompilerException]) =>
      s"""|Model should have compiled but failed with the following messages:
          |${failures.stream.mkString("\n")}""".stripMargin
    CompiledModel.fromNlogoContents(wolfSheep) valueOr { e => fail(modelShouldHaveCompiled(e)) }
  }

  private val widgetModel = CompiledModel.fromNlogoContents(
    Source.fromFile("public/modelslib/test/tortoise/Widgets.nlogo").mkString
  )

}

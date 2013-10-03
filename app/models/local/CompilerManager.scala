package models.local

import
  akka.{ actor, pattern },
    actor.Actor,
    pattern.ask

import org.nlogo.api.{ WorldDimensions, ModelReader, ModelSection }

private[local] class CompilerManager extends Actor {

  import CompilerMessages._

  private val WorldDimensionIndices = 17 to 20

  private var modelState = {
    val dimensions     = WorldDimensions(-16, 16, -16, 16)
    val (js, compiler) = NetLogoCompiler().compileModelToJS("", dimensions)
    ModelState(compiler, dimensions, js)
  }

  override def receive = {

    case Execute(agentType, cmd) =>
      sender ! updateStateAndGetJS {
        modelState =>
          val (js, compiler) = modelState.compiler(agentType, cmd)
          modelState.copy(compiler = compiler, cachedJS = js)
      }

    case Open(nlogoContents) =>
      sender ! updateStateAndGetJS {
        modelState =>
          val (source, dimensions) = extractSourceAndDimensions(nlogoContents)
          val (js, compiler)       = modelState.compiler.compileModelToJS(source, dimensions)
          modelState.copy(compiler = compiler, dimensions = dimensions, cachedJS = js)
      }

    case Compile(source) =>
      sender ! updateStateAndGetJS {
        modelState =>
          val (js, compiler) = modelState.compiler.compileModelToJS(source, modelState.dimensions)
          modelState.copy(compiler = compiler, cachedJS = js)
      }

  }

  private def updateStateAndGetJS[T](genState: (ModelState) => ModelState): String = {
    modelState = genState(modelState)
    modelState.cachedJS
  }

  private def extractSourceAndDimensions(nlogoContents: String): (String, WorldDimensions) = {

    val modelMap  = ModelReader.parseModel(nlogoContents)
    val interface = modelMap(ModelSection.Interface)
    val source    = modelMap(ModelSection.Code).mkString("\n")

    val Seq(minX, maxX, minY, maxY) = WorldDimensionIndices map { x => interface(x).toInt }
    val dimensions = WorldDimensions(minX, maxX, minY, maxY)

    (source, dimensions)

  }

  private case class ModelState(compiler: NetLogoCompiler, dimensions: WorldDimensions, cachedJS: String)

}

protected[local] object CompilerMessages {
  case class  Execute(agentType: String, cmd: String)
  case class  Open(nlogoContents: String)
  case class  Compile(source: String)
}


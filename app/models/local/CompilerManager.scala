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
    val source         = ""
    val dimensions     = WorldDimensions(-16, 16, -16, 16)
    val (js, compiler) = NetLogoCompiler().generateModelState(source, dimensions)
    ModelState(compiler, dimensions, source, js)
  }

  override def receive = {

    case Execute(agentType, cmd) =>
      sender ! updateStateAndGetJS {
        modelState =>
          val (js, compiler) = modelState.compiler(agentType, cmd)
          modelState.copy(compiler = compiler, cachedJS = js)
      }

    case GetModelState =>
      sender ! updateStateAndGetJS(identity)

    case Open(nlogoContents) =>
      sender ! updateStateAndGetJS {
        modelState =>
          val (source, dimensions) = extractSourceAndDimensions(nlogoContents)
          val (js, compiler)       = modelState.compiler.generateModelState(source, dimensions)
          modelState.copy(compiler = compiler, dimensions = dimensions, source = source, cachedJS = js)
      }

    case Compile(source) =>
      sender ! updateStateAndGetJS {
        modelState =>
          val (js, compiler) = modelState.compiler.generateModelState(source, modelState.dimensions)
          modelState.copy(compiler = compiler, source = source, cachedJS = js)
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

    // HLists could be applied nicely here --JAB (10/1/13)
    val Seq(minX, maxX, minY, maxY) = WorldDimensionIndices map { x => interface(x).toInt }
    val dimensions = WorldDimensions(minX, maxX, minY, maxY)

    (source, dimensions)

  }

  private case class ModelState(compiler: NetLogoCompiler, dimensions: WorldDimensions, source: String, cachedJS: String)

}

protected[local] object CompilerMessages {
  case class  Execute(agentType: String, cmd: String)
  case object GetModelState
  case class  Open(nlogoContents: String)
  case class  Compile(source: String)
}


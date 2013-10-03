package models.local

import
  akka.{ actor, pattern },
    actor.Actor,
    pattern.ask

import org.nlogo.api.{ WorldDimensions, ModelReader, ModelSection }

private[local] class CompilerManager extends Actor {

  import CompilerMessages._

  private val WorldDimensionIndices = 17 to 20

  private var compiler = NetLogoCompiler()

  override def receive = {

    case Execute(agentType, cmd) =>
      sender ! updateStateAndGetJS(_.runCommand(agentType, cmd))

    case Open(nlogoContents) =>
      sender ! updateStateAndGetJS {
        compiler =>
          val (source, dimensions) = extractSourceAndDimensions(nlogoContents)
          NetLogoCompiler(dimensions)(source)
      }

    case Compile(source) =>
      sender ! updateStateAndGetJS(_(source))

  }

  private def updateStateAndGetJS[T](genState: (NetLogoCompiler) => (NetLogoCompiler, String)): String = {
    val (newCompiler, js) = genState(compiler)
    compiler = newCompiler
    js
  }

  private def extractSourceAndDimensions(nlogoContents: String): (String, WorldDimensions) = {

    val modelMap  = ModelReader.parseModel(nlogoContents)
    val interface = modelMap(ModelSection.Interface)
    val source    = modelMap(ModelSection.Code).mkString("\n")

    val Seq(minX, maxX, minY, maxY) = WorldDimensionIndices map { x => interface(x).toInt }
    val dimensions = WorldDimensions(minX, maxX, minY, maxY)

    (source, dimensions)

  }

}

protected[local] object CompilerMessages {
  case class  Execute(agentType: String, cmd: String)
  case class  Open(nlogoContents: String)
  case class  Compile(source: String)
}


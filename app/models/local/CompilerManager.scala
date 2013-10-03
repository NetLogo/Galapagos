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
    case Open(nlogoContents)     => sender ! updateAndGetJS(_        => makeCompiler(nlogoContents))
    case Compile(source)         => sender ! updateAndGetJS(compiler => compiler(source))
    case Execute(agentType, cmd) => sender ! updateAndGetJS(compiler => compiler.runCommand(agentType, cmd))
  }

  private def updateAndGetJS[T](genCompiler: (NetLogoCompiler) => (NetLogoCompiler, String)): String = {
    val (newCompiler, js) = genCompiler(compiler)
    compiler = newCompiler
    js
  }

  private def makeCompiler(nlogoContents: String): (NetLogoCompiler, String) = {

    val modelMap  = ModelReader.parseModel(nlogoContents)
    val interface = modelMap(ModelSection.Interface)
    val source    = modelMap(ModelSection.Code).mkString("\n")

    val Seq(minX, maxX, minY, maxY) = WorldDimensionIndices map { x => interface(x).toInt }
    val dimensions = WorldDimensions(minX, maxX, minY, maxY)

    NetLogoCompiler(dimensions)(source)

  }

}

protected[local] object CompilerMessages {
  case class Execute(agentType: String, cmd: String)
  case class Open(nlogoContents: String)
  case class Compile(source: String)
}


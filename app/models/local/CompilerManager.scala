package models.local

import
  akka.actor.Actor

private[local] class CompilerManager extends Actor {

  import CompilerMessages._

  private var compiler = NetLogoCompiler.blank

  override def receive = {
    case Open(nlogoContents)     => sender ! updateAndGetJS(_        => NetLogoCompiler.fromNLogoFile(nlogoContents))
    case Compile(source)         => sender ! updateAndGetJS(compiler => compiler.recompile(source))
    case Execute(agentType, cmd) => sender ! updateAndGetJS(compiler => compiler.runCommand(agentType, cmd))
  }

  private def updateAndGetJS[T](genCompiler: (NetLogoCompiler) => (NetLogoCompiler, String)): String = {
    val (newCompiler, js) = genCompiler(compiler)
    compiler = newCompiler
    js
  }

}

protected[local] object CompilerMessages {
  case class Execute(agentType: String, cmd: String)
  case class Open(nlogoContents: String)
  case class Compile(source: String)
}


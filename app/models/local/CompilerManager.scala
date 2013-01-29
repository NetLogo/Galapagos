package models.local

import
  akka.{ actor, pattern },
    actor.Actor,
    pattern.ask

protected[local] class CompilerManager extends Actor {

  import CompilerMessages._

  private var compiler = NetLogoCompiler()

  override def receive = {
    case Execute(agentType, cmd) => sender ! updateCompiler(compiler(agentType, cmd))
    case GetModelState           => sender ! updateCompiler(compiler.generateModelState)
  }

  private def updateCompiler(jsAndCompiler: (String, NetLogoCompiler)) = {
    jsAndCompiler match {
      case (js, newCompiler) =>
        compiler = newCompiler
        js
    }
  }

}

protected[local] object CompilerMessages {
  case class  Execute(agentType: String, cmd: String)
  case object GetModelState
}


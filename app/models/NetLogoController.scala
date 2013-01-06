package models

import java.io.File

import play.api.libs.concurrent.Akka
import play.api.Play.current

import akka.actor.{ Actor, Props }

import org.nlogo.headless.HeadlessWorkspace
import org.nlogo.mirror.{ Mirrorable, Mirrorables, Mirroring, Update }

class NetLogoController extends Actor {
  private var currentState: Mirroring.State = Map()

  private val modelsPath = "public/models/"
  private val modelName  = "Wolf Sheep Predation"
  private lazy val ws    = workspace(new File(modelsPath + modelName + ".nlogo"))

  private val executor = Akka.system.actorOf(Props(new BackgroundExecutor))
  private val viewDiffer = Akka.system.actorOf(Props(new ViewDiffer))

  // Commands should execute in the background so that they don't lock up the
  // whole controller
  private class BackgroundExecutor extends Actor {
    def receive = {
      case Execute(agentType, cmd) =>
        sender ! CommandOutput(agentType, ws.execute(agentType, cmd))
    }
  }

  // Calculating the state updates can take a while, and thus requests for
  // view updates can build up, filling the Actor's mailbox. Hence, we execute
  // diffs in the background so that the NetLogoController is free to deal with
  // other messages (especially halts).
  private class ViewDiffer extends Actor {
    def receive = {
      case RequestViewUpdate =>
        val (newState, update) = getStateUpdate(currentState)
        currentState = newState
        sender ! ViewUpdate(Serializer.serialize(update))
      case RequestViewState =>
        sender ! ViewUpdate(Serializer.serialize(getStateUpdate(Map())._2))
    }
  }

  def receive = {
    case Execute(agentType, cmd) =>
      executor.forward(Execute(agentType, cmd))
    case RequestViewUpdate =>
      viewDiffer.forward(RequestViewUpdate)
    case RequestViewState =>
      viewDiffer.forward(RequestViewState)
    case Halt =>
      ws.halt()
  }

  private def getStateUpdate(baseState: Mirroring.State): (Mirroring.State, Update)  =
    ws.world.synchronized {
      val mirrorables = Mirrorables.allMirrorables(ws.world, ws.plotManager.plots, Seq())
      Mirroring.diffs(baseState, mirrorables)
    }

  protected def workspace(file: File) : WebWorkspace = {
    val wspace = HeadlessWorkspace.newInstance(classOf[WebWorkspace]).asInstanceOf[WebWorkspace]
    wspace.openString(io.Source.fromFile(file).mkString)
    wspace
  }
}

case class Execute(agentType: String, cmd: String)
case object RequestViewUpdate
case object RequestViewState
case object Halt

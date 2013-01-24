package models

import java.io.File

import play.api.libs.concurrent.Akka
import play.api.Play.current

import akka.actor.{ Actor, Props }
import akka.util.duration._

import org.nlogo.headless.HeadlessWorkspace
import org.nlogo.mirror.{ Mirrorable, Mirrorables, Mirroring, Update }

class NetLogoController extends Actor {
  private var currentState: Mirroring.State = Map()

  private val modelsPath = "public/models/"
  private val modelName  = "Wolf Sheep Predation"
  private lazy val ws    = workspace(new File(modelsPath + modelName + ".nlogo"))

  private val executor = Akka.system.actorOf(Props(new Executor))
  private val viewGen = Akka.system.actorOf(Props(new ViewUpdateGenerator))
  private val halter = Akka.system.actorOf(Props(new Halter))
  private val hlController = Akka.system.actorOf(Props(new HighLevelController))

  ///////////
  // Tasks //
  ///////////
  private class Executor extends Actor {
    def receive = {
      case Execute(agentType, cmd) => // possibly long running
        // ws.execute returns normally even if NetLogo is interrupted with a
        // halt, so no zombie processes should be created.
        sender ! CommandOutput(agentType, ws.execute(agentType, cmd))
    }
  }

  private class ViewUpdateGenerator extends Actor {
    def receive = {
      case RequestViewUpdate => // possibly long running
        val (newState, update) = getStateUpdate(currentState)
        currentState = newState
        sender ! ViewUpdate(Serializer.serialize(update))
      case RequestViewState => // possibly long running
        sender ! ViewUpdate(Serializer.serialize(getStateUpdate(Map())._2))
    }
  }

  private class Halter extends Actor {
    def receive = { case Halt => ws.halt() } 
  }

  private class HighLevelController extends Actor {
    var speed = 30d
    var going = false
    private case object GoLoop

    def receive = {
      case GoLoop =>
        executor ! Execute("observer", "go")
        if (going) Akka.system.scheduler.scheduleOnce((speed / 1000d) seconds, self, GoLoop)
      case Go =>
        going = true
        self ! GoLoop
      case Stop =>
        going = false
      case Setup =>
        executor ! Execute("observer", "setup")
    }
  }

  ////////////////
  // Delegation //
  ////////////////
  def receive = {
    case Execute(agentType, cmd) => executor.forward(Execute(agentType, cmd))
    case RequestViewUpdate => viewGen.forward(RequestViewUpdate)
    case RequestViewState => viewGen.forward(RequestViewState)
    case Halt => halter.forward(Halt)
    case Go => hlController.forward(Go)
    case Stop => hlController.forward(Stop)
    case Setup => hlController.forward(Setup)
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
case object Go
case object Stop
case object Setup

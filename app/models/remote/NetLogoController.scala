package models.remote

import
  java.io.File

import
  akka.actor.{ Actor, Props }

import
  org.nlogo.{ headless, mirror },
    headless.HeadlessWorkspace,
    mirror.{ Mirrorables, Mirroring, Update }

import
  concurrent.duration._

import
  play.api.libs.concurrent.Akka

import
  models.core.{ NetLogoControllerMessages, WebInstanceMessages }

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext

class NetLogoController extends Actor {

  import NetLogoControllerMessages._
  import WebInstanceMessages._

  private var currentState: Mirroring.State = Map()

  private val ws = workspace(ModelManager("Wolf Sheep Predation").get)

  private val executor     = Akka.system.actorOf(Props(new Executor))
  private val viewGen      = Akka.system.actorOf(Props(new ViewUpdateGenerator))
  private val halter       = Akka.system.actorOf(Props(new Halter))
  private val hlController = Akka.system.actorOf(Props(new HighLevelController))
  private val modelManager = Akka.system.actorOf(Props(new ModelManager))

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
    var speed = 60d
    var going = false
    private case object GoLoop

    def receive = {
      case GoLoop =>
        executor ! Execute("observer", "go")
        if (going) {Akka.system.scheduler.scheduleOnce((1d / speed).seconds) {self ! GoLoop}}
      case Go =>
        if (!going) {
          going = true
          self ! GoLoop
        }
      case Stop =>
        going = false
      case Setup =>
        executor ! Execute("observer", "setup")
    }
  }

  private class ModelManager extends Actor {
    def receive = {
      case Open(modelName) =>
    } 
  }

  ////////////////
  // Delegation //
  ////////////////

  def receive = {
    case Execute(agentType, cmd) => executor.forward(Execute(agentType, cmd))
    case Go                      => hlController.forward(Go)
    case Halt                    => halter.forward(Halt)
    case RequestViewUpdate       => viewGen.forward(RequestViewUpdate)
    case RequestViewState        => viewGen.forward(RequestViewState)
    case Stop                    => hlController.forward(Stop)
    case Setup                   => hlController.forward(Setup)
    case Open(modelName)         => modelManager.forward(Open(modelName))
  }

  private def getStateUpdate(baseState: Mirroring.State) : (Mirroring.State, Update)  =
    ws.world.synchronized {
      val widgetValues = Seq() // Eventually, this might have something in it.  Nicolas currently only plans to ever use for monitor values, though --JAB (1/22/13)
      val mirrorables  = Mirrorables.allMirrorables(ws.world, widgetValues)
      Mirroring.diffs(baseState, mirrorables)
    }

  protected def workspace(file: File) : WebWorkspace = {
    val wspace = HeadlessWorkspace.newInstance(classOf[WebWorkspace]).asInstanceOf[WebWorkspace]
    wspace.openString(io.Source.fromFile(file).mkString)
    wspace
  }

}


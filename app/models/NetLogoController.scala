package models

import
  java.io.File

import
  akka.actor.{ Actor, Props }

import
  org.nlogo.{ headless, mirror },
    headless.HeadlessWorkspace,
    mirror.{ Mirrorables, Mirroring, Update }

import
  play.api.libs.concurrent.Akka

import play.api.Play.current

class NetLogoController extends Actor {
  private var currentState: Mirroring.State = Map()

  private val modelsPath = "public/models/"
  private val modelName  = "Wolf Sheep Predation"
  private lazy val ws    = workspace(new File(modelsPath + modelName + ".nlogo"))

  private val executor = Akka.system.actorOf(Props(new Executor))
  private val viewGen = Akka.system.actorOf(Props(new ViewUpdateGenerator))
  private val halter = Akka.system.actorOf(Props(new Halter))

  ///////////
  // Tasks //
  ///////////
  private class Executor extends Actor {
    def receive = {
      case Execute(agentType, cmd) => // possibly long running
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

  ////////////////
  // Delegation //
  ////////////////
  def receive = {
    case Execute(agentType, cmd) => executor.forward(Execute(agentType, cmd))
    case RequestViewUpdate => viewGen.forward(RequestViewUpdate)
    case RequestViewState => viewGen.forward(RequestViewState)
    case Halt => halter.forward(Halt)
  }

  private def getStateUpdate(baseState: Mirroring.State): (Mirroring.State, Update)  =
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

case class Execute(agentType: String, cmd: String)
case object RequestViewUpdate
case object RequestViewState
case object Halt

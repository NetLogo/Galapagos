package models.remote

import
  java.io.File

import
  akka.actor.{ Actor, ActorRef, Props }

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

//@ One day, I'll kill all of this insane, unscalable, impossible-to-reason-about actor proliferation
//  and implement a priority mailbox, like things should have been done to begin with.  --Jason (2/26/13)
class NetLogoController(channel: ActorRef) extends Actor {

  import NetLogoControllerMessages._
  import WebInstanceMessages._

  private var currentState: Mirroring.State = Map()

  private var ws = workspace(io.Source.fromFile(ModelManager("Wolf_Sheep_Predation").get).mkString)

  private val executor     = Akka.system.actorOf(Props(new Executor))
  private val viewManager  = Akka.system.actorOf(Props(new ViewStateManager))
  private val halter       = Akka.system.actorOf(Props(new Halter))
  private val hlController = Akka.system.actorOf(Props(new HighLevelController))

  ///////////
  // Tasks //
  ///////////

  private class Executor extends Actor {
    def receive = {
      case Execute(agentType, cmd) => // possibly long running
        // ws.execute returns normally even if NetLogo is interrupted with a
        // halt, so no zombie processes should be created.
        channel ! CommandOutput(agentType, ws.execute(agentType, cmd))

      case Compile(source) =>
        import collection.immutable.ListMap
        import org.nlogo.api.{ Program, Version }
        // TODO: Clean this up. This is what I've cobbled together through trial
        // and error and looking through NetLogo code.
        // This is based on CompilerManager.compileAll

        // Write failing tests that isolates problems.
        // Using api.Program.empty() will do it cleanly, but I'll lose variables.
        val results = ws.compiler.compileProgram(
          source, ws.world.program.copy(breeds = ListMap()), ws.getExtensionManager)
        ws.procedures = results.proceduresMap
        ws.init()
        // FIXME: Global and turtle variables appear to be preserved during
        // recomplie, but patch variables do not.
        ws.world.rememberOldProgram()
        ws.world.program(results.program)
        ws.world.realloc()
        //ws.codeBits.clear()
        //ws.world.realloc()

      case OpenModel(nlogoContents) =>
        ws.clearAll()
        ws.dispose()
        ws = workspace(nlogoContents) // Grrr....  At some point, we should fix `HeadlessWorkspace` to be able to open a new model --Jason
        viewManager ! ResetViewState

    }
  }

  private class ViewStateManager extends Actor {
    def receive = {
      case RequestViewUpdate => // possibly long running
        val (newState, update) = getStateUpdate(currentState)
        currentState = newState
        channel ! ViewUpdate(Serializer.serialize(update))
      case RequestViewState => // possibly long running
        channel ! ViewUpdate(Serializer.serialize(getStateUpdate(Map())._2))
      case ResetViewState =>
        currentState = Map()
    }
  }

  private class Halter extends Actor {
    def receive = { case Halt => ws.halt() }
  }

  private class HighLevelController extends Actor {

    var speed   = 60d
    var isGoing = false

    def receive = {
      case Go =>
        if (!isGoing) {
          isGoing = true
          go()
        }
      case Stop =>
        isGoing = false
      case Setup =>
        executor ! Execute("observer", "setup")
    }

    def go() {
      executor ! Execute("observer", "go")
      if (isGoing) Akka.system.scheduler.scheduleOnce((1d / speed).seconds){ go() }
    }

  }

  ////////////////
  // Delegation //
  ////////////////

  def receive = {
    case msg @ Execute(_, _)     => executor.forward(msg)
    case msg @ Compile(_)        => executor.forward(msg)
    case msg @ Go                => hlController.forward(msg)
    case msg @ Halt              => halter.forward(msg)
    case msg @ OpenModel(_)      => executor.forward(msg)
    case msg @ RequestViewUpdate => viewManager.forward(msg)
    case msg @ RequestViewState  => viewManager.forward(msg)
    case msg @ Stop              => hlController.forward(msg)
    case msg @ Setup             => hlController.forward(msg)
  }

  private def getStateUpdate(baseState: Mirroring.State) : (Mirroring.State, Update)  =
    ws.world.synchronized {
      val widgetValues = Seq() // Eventually, this might have something in it.  Nicolas currently only plans to ever use for monitor values, though --JAB (1/22/13)
      val mirrorables  = Mirrorables.allMirrorables(ws.world, widgetValues)
      Mirroring.diffs(baseState, mirrorables)
    }

  protected def workspace(nlogoContents: String) : WebWorkspace = {
    val wspace = HeadlessWorkspace.newInstance(classOf[WebWorkspace]).asInstanceOf[WebWorkspace]
    wspace.openString(nlogoContents)
    wspace
  }

}


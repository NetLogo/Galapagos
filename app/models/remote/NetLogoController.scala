package models.remote

import
  java.io.File

import
  akka.actor.{ Actor, ActorRef, Props, PoisonPill }

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

  // def for executor so that multiple netlogo commands can run simultaneously.
  // netlogo handles the scheduling.
  // This also helps ensure that halt won't just open up NetLogo to take the next
  // job the queue; it will actually stop all jobs as it's supposed to.
  private def executor     = Akka.system.actorOf(Props(new Executor))
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
        viewManager ! ViewNeedsUpdate
        self ! PoisonPill
    }
  }



  // Calculating diffs takes a long time. This keeps track of if we actually
  // have to do it.
  private var needUpdate: Boolean = false

  // We need synchronous versions on view-updating methods for model opening.
  // modelruns gets really unhappy about things changing from under its feet,
  // so the model opening process needs direct control.
  // TODO: Find a better solution! This is gross!
  private def sendViewUpdate() {
    val (newState, update) = getStateUpdate(currentState)
    currentState = newState
    channel ! ViewUpdate(Serializer.serialize(update))
    needUpdate = false
  }

  // Note that this CANNOT set current state to this new state. This update
  // won't contain deaths.
  private def sendViewState() {
    channel ! ViewUpdate(Serializer.serialize(getStateUpdate(Map())._2))
  }

  private def resetViewState() {
    currentState = Map()
  }

  private class ViewStateManager extends Actor {
    def receive = {
      case ViewNeedsUpdate =>
        needUpdate = true
      case RequestViewUpdate => // possibly long running
        if (needUpdate) {
          sendViewUpdate()
        }
      case RequestViewState => // possibly long running
        sendViewState()
      case ResetViewState =>
        resetViewState()

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
        println("opening model")
        stop()
        ws.halt()
        // Clear out the current state to reset people's views
        ws.execute("observer", "ca")
        // Force people's views so they don't get turtles stuck on screen.
        // After resetting the view, modelruns won't
        // know anything about previous turtles, so if the next model uses
        // fewer turtles, the turtles with high who numbers will be stuck on
        // screen.
        sendViewUpdate()
        // Reset the view state. If we don't do this, modelruns gets really
        // unhappy about different numbers of variables and such (as far as I
        // can tell).
        resetViewState()
        ws.clearAll()
        ws.dispose()
        ws = workspace(nlogoContents) // Grrr....  At some point, we should fix `HeadlessWorkspace` to be able to open a new model --Jason
        sendViewUpdate()
        println("finished opening model")
    }
  }

  private class Halter extends Actor {
    def receive = { case Halt => ws.halt() }
  }


  // Model opening needs direct control over this.
  var isGoing = false
  def stop() {
    println("stopping")
    isGoing = false
  }

  private class HighLevelController extends Actor {
    var speed   = 60d

    def go() {
      if (isGoing) {
        executor ! Execute("observer", "go")
        Akka.system.scheduler.scheduleOnce((1d / speed).seconds){ go() }
      }
    }
    def receive = {
      case Go =>
        if (!isGoing) {
          isGoing = true
          go()
        }
      case Stop =>
        stop()
      case Setup =>
        executor ! Execute("observer", "setup")
    }
  }


  ////////////////
  // Delegation //
  ////////////////

  def receive = {
    case msg @ Execute(_, _)     => executor.forward(msg)
    case msg @ Compile(_)        => viewManager.forward(msg)
    case msg @ Go                => hlController.forward(msg)
    case msg @ Halt              => halter.forward(msg)
    case msg @ OpenModel(_)      => viewManager.forward(msg)
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


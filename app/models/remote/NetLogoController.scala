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
// We want true parallelization between actors here; e.g. a halt must be runnable
// anytime. While this structuring may have begun as a hacky priority inbox
// replacement, it is now being used properly to declare synchronization and
// parallelizability. --Bryan (6/9/13)
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
  private val stateManager = Akka.system.actorOf(Props(new StateManager))
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
        stateManager ! ViewNeedsUpdate
        self ! PoisonPill
    }
  }

  /**
   * Syncrhonizes everything that manipulates and reports the state of NetLogo.
   * This includes view update calculation, model opening, and compiling. Execution
   * is handled separately since it needs to be interruptable by model opening
   * and is really nice to be run in parallel to view update calculation.
   * Furthermore, execution problems are handled fairly gracefully (you just get
   * a NetLogo error reported).
   * Anything that needs execution to stop temporarily should call stop() and
   * ws.halt().
   **/
  // TODO: Synchronize execution with opening models and maybe compiling.
  private class StateManager extends Actor {
    // Calculating diffs takes a long time. This keeps track of if we actually
    // have to do it.
    private var needUpdate: Boolean = false

    // We need synchronous versions on view-updating methods for model opening.
    // modelruns gets really unhappy about things changing from under its feet,
    // so the model opening process needs direct control.
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
        // TODO: Clean this up. Need tests to figure out exactly when this works.
        // This is based on CompilerManager.compileAll
        // Using api.Program.empty() for the program will do it cleanly, but it
        // loses variables.

        // If we don't blank out breeds on compile, it complains about breeds
        // being redefined. However, if we just toss breeds and the currently
        // opened model has plots that use breeds, when a user deletes the breeds
        // line in the program, calling `reset-ticks` errors. As a workaround,
        // we just sneak the old breeds back in when putting results.program
        // into the world program.
        // TODO: When we figure out a new widget system, the need for this should
        // be removed.
        val breeds = ws.world.program.breeds
        val results = ws.compiler.compileProgram(
          source, ws.world.program.copy(breeds = ListMap()), ws.getExtensionManager)
        ws.procedures = results.proceduresMap
        ws.init()
        // FIXME: Global and turtle variables appear to be preserved during
        // recomplie, but patch variables do not.
        ws.world.rememberOldProgram()
        // world.program must be set to results.program. We sneak the old breeds
        // back in so that widgets depending on the breeds don't freakout if their
        // not there anymore.
        ws.world.program(results.program.copy(
          breeds = results.program.breeds ++ breeds))
        ws.world.realloc()

      case OpenModel(nlogoContents) =>
        channel ! CommandOutput("info", "opening model...")
        play.api.Logger.info("opening model")
        stop()
        play.api.Logger.info("halting")
        ws.halt()
        // Clear out the current state to reset people's views
        play.api.Logger.info("clearing")
        ws.execute("observer", "ca")
        // Force people's views so they don't get turtles stuck on screen.
        // After resetting the view, modelruns won't
        // know anything about previous turtles, so if the next model uses
        // fewer turtles, the turtles with high who numbers will be stuck on
        // screen.
        play.api.Logger.info("sending view update")
        sendViewUpdate()
        // Reset the view state. If we don't do this, modelruns gets really
        // unhappy about different numbers of variables and such (as far as I
        // can tell).
        play.api.Logger.info("resetting view")
        resetViewState()
        play.api.Logger.info("clearing workspace")
        ws.clearAll()
        play.api.Logger.info("disposing workspace")
        ws.dispose()
        play.api.Logger.info("creating new workspace from new model")
        ws = workspace(nlogoContents) // Grrr....  At some point, we should fix `HeadlessWorkspace` to be able to open a new model --Jason
        play.api.Logger.info("sending view update")
        sendViewUpdate()
        println("finished opening model")
        channel ! CommandOutput("info", "model successfully opened")
    }
  }

  /**
   * Needs to be parallelized with everything. Should runnable at any time no
   * matter what.
   **/
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
    case msg @ Compile(_)        => stateManager.forward(msg)
    case msg @ Go                => hlController.forward(msg)
    case msg @ Halt              => halter.forward(msg)
    case msg @ OpenModel(_)      => stateManager.forward(msg)
    case msg @ RequestViewUpdate => stateManager.forward(msg)
    case msg @ RequestViewState  => stateManager.forward(msg)
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


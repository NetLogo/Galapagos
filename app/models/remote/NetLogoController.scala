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

import workspace.WebWorkspace

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

  private var ws = workspace(io.Source.fromFile(ModelManager("Wolf_Sheep_Predation").get).mkString)

  // def for executor so that multiple netlogo commands can run simultaneously.
  // netlogo handles the scheduling.
  // This also helps ensure that halt won't just open up NetLogo to take the next
  // job the queue; it will actually stop all jobs as it's supposed to.
  private def executor     = Akka.system.actorOf(Props(new Executor))
  private val stateManager = Akka.system.actorOf(Props(new StateManager))
  private val halter       = Akka.system.actorOf(Props(new Halter))

  ///////////
  // Tasks //
  ///////////

  private class Executor extends Actor {
    def receive = {
      case Execute(agentType, cmd) => // possibly long running
        play.api.Logger.info("Executing (" + agentType + ", " + cmd + ")")
        // ws.execute returns normally even if NetLogo is interrupted with a
        // halt, so no zombie processes should be created.
        channel ! CommandOutput(agentType, ws.execute(agentType, cmd))
        play.api.Logger.info("Completed (" + agentType + ", " + cmd + ")")
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
  private class StateManager extends Actor {

    // We need synchronous versions on view-updating methods for model opening.
    // modelruns gets really unhappy about things changing from under its feet,
    // so the model opening process needs direct control.

    private def sendUpdate(update: Update) {
      channel ! ViewUpdate(Serializer.serialize(update))
    }

    private def sendViewUpdate() {
      sendUpdate(ws.updateState())
    }

    private def sendViewState() {
      play.api.Logger.info("Sending view state")
      sendUpdate(ws.getStateUpdate(Map())._2)
    }

    private def openModel(nlogoContents: String) {
      channel ! CommandOutput("info", "opening model...")
      play.api.Logger.info("Opening model")
      stop()
      ws.halt()
      // Clear out the current state to reset people's views
      ws.execute("observer", "ca")
      ws.clearAll()
      sendViewUpdate()
      ws.dispose()
      ws = workspace(nlogoContents) // Grrr....  At some point, we should fix `HeadlessWorkspace` to be able to open a new model --Jason
      play.api.Logger.info("Finished opening model")
      channel ! CommandOutput("info", "model successfully opened")
    }

    def receive = {
      case RequestViewUpdate        => if (ws.updatePending) sendViewUpdate()
      // possibly long running
      case RequestViewState         => sendViewState()
      case Compile(source)          => ws.setActiveCode(source)
      case OpenModel(nlogoContents) => openModel(nlogoContents)
    }
  }

  /**
   * Needs to be parallelized with everything. Should runnable at any time no
   * matter what.
   **/
  private class Halter extends Actor {
    def receive = { case Halt => ws.halt() }
  }

  def go() {
    ws.go("go")
    channel ! CommandOutput("info", "Going")
  }

  def stop() {
    ws.stop("go")
    channel ! CommandOutput("info", "Stopping")
  }

  def setup() {
    executor ! Execute("observer", "setup")
  }

  ////////////////
  // Delegation //
  ////////////////

  def receive = {
    case msg @ Execute(_, _)     => executor.forward(msg)
    case msg @ Compile(_)        => stateManager.forward(msg)
    case msg @ Halt              => halter.forward(msg)
    case msg @ OpenModel(_)      => stateManager.forward(msg)
    case msg @ RequestViewUpdate => stateManager.forward(msg)
    case msg @ RequestViewState  => stateManager.forward(msg)
    case msg @ ViewNeedsUpdate   => stateManager.forward(msg)
    case msg @ Go                => go()
    case msg @ Stop              => stop()
    case msg @ Setup             => setup()
  }

  protected def workspace(nlogoContents: String) : WebWorkspace = {
    val wspace = HeadlessWorkspace.newInstance(classOf[WebWorkspace]).asInstanceOf[WebWorkspace]

    wspace.openString(nlogoContents)
    wspace
  }

}


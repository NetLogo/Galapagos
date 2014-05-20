package models.remote

import
  akka.actor.{ Actor, ActorRef, Props, PoisonPill }

import
  org.nlogo.{ api, compile, headless, mirror, nvm, tortoise, workspace => ws },
    api.model.ModelReader,
    compile.front.FrontEnd,
    headless.HeadlessWorkspace,
    mirror.Update,
    nvm.DefaultParserServices,
    tortoise.json.JSONSerializer,
    ws.AbstractWorkspace

import
  play.api.{ libs, Logger },
    libs.concurrent.Akka

import
  models.{ core, Util },
    core.{ NetLogoControllerMessages, WebInstanceMessages },
    Util.usingSource

import
  workspace.WebWorkspace

import play.api.Play.current

/**
 * A parallelized interface for NetLogo.
 */
class NetLogoController(channel: ActorRef) extends Actor {

  import NetLogoControllerMessages._
  import WebInstanceMessages._

  // avoids annoying dock icon on Mac OS X, and is otherwise just generally
  // a good idea (it prevents accidental dependence on being run inside a GUI)
  // --SAT (11/24/13)
  AbstractWorkspace.setHeadlessProperty()

  private var ws = workspace(usingSource(_.fromFile("./public/modelslib/Sample Models/Biology/Wolf Sheep Predation.nlogo"))(_.mkString))

  // def for executor so that multiple netlogo commands can run simultaneously.
  // netlogo handles the scheduling.
  private def executor     = Akka.system.actorOf(Props(new Executor))
  private val stateManager = Akka.system.actorOf(Props(new StateManager))

  private class Executor extends Actor {
    def receive = {
      case Execute(agentType, cmd) => // possibly long running
        Logger.info(s"Executing ($agentType, $cmd)")
        // ws.execute returns normally even if NetLogo is interrupted with a
        // halt, so no zombie processes should be created.
        channel ! CommandOutput(agentType, ws.execute(agentType, cmd))
        Logger.info(s"Completed ($agentType, $cmd)")
        self ! PoisonPill
    }
  }

  /**
   * Synchronizes everything that manipulates and reports the state of NetLogo.
   * This includes view update calculation, model opening, and compiling.
   * Although execution changes the state of NetLogo, it can't, for instance,
   * introduce new variables, so can be run in parallel with everything here.
   **/
  private class StateManager extends Actor {

    private def sendUpdate(update: Update): Unit =
      channel ! ViewUpdate(JSONSerializer.serialize(update))

    private def sendPendingUpdate(): Unit =
      if (ws.updatePending)
        sendUpdate(ws.updateState)

    private def openModel(nlogoContents: String): Unit = {
      channel ! CommandOutput("info", "opening model...")
      Logger.info("Opening model")
      ws.halt()
      // Clear out the current state to reset people's views
      ws.execute("observer", "ca")
      ws.clearAll()
      sendPendingUpdate()
      ws.dispose()
      ws = workspace(nlogoContents) // Grrr....  At some point, we should fix `HeadlessWorkspace` to be able to open a new model --Jason
      Logger.info("Finished opening model")
      channel ! CommandOutput("info", "model successfully opened")
    }

    def receive = {
      case RequestViewUpdate        => sendPendingUpdate()
      case RequestViewState         => sendUpdate(ws.getStateUpdate(Map())._2)
      case Compile(source)          => ws.setActiveCode(source)
      case OpenModel(nlogoContents) => openModel(nlogoContents)
    }
  }

  private def go(): Unit = {
    ws.go("go")
    channel ! CommandOutput("info", "Going")
  }

  private def stop(): Unit = {
    ws.stop("go")
    channel ! CommandOutput("info", "Stopping")
  }

  private def setup(): Unit = {
    executor ! Execute("observer", "setup")
  }

  ////////////////
  // Delegation //
  ////////////////

  def receive = {
    case msg @ Execute(_, _)     => executor.forward(msg)
    case msg @ Compile(_)        => stateManager.forward(msg)
    case msg @ OpenModel(_)      => stateManager.forward(msg)
    case msg @ RequestViewUpdate => stateManager.forward(msg)
    case msg @ RequestViewState  => stateManager.forward(msg)
    case msg @ ViewNeedsUpdate   => stateManager.forward(msg)
    case msg @ Go                => go()
    case msg @ Stop              => stop()
    case msg @ Setup             => setup()
    case msg @ Halt              => ws.halt()
  }

  protected def workspace(nlogoContents: String): WebWorkspace = {

    val wspace = HeadlessWorkspace.newInstance(classOf[WebWorkspace]).asInstanceOf[WebWorkspace]
    val model  = ModelReader.parseModel(nlogoContents, new DefaultParserServices(FrontEnd))

    wspace.openModel(model)
    wspace.setOutputCallback((output: String) => channel ! CommandOutput("observer", output))
    wspace

  }
}


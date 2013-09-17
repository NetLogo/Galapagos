package models.remote.workspace

import org.nlogo.headless.HeadlessWorkspace

import collection.immutable.ListSet

import akka.actor.{ Actor, ActorRef, Props }
import play.api.libs.concurrent.Akka
import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext
import concurrent.duration._

trait ForeverRunner extends HeadlessWorkspace {
  this: Executor =>

  // Halt is the only method in ForeverRunner that should directly access
  // runningTasks! All others should go through looper!
  private var runningTasks: ListSet[String] = ListSet()

  private val looper = Akka.system.actorOf(Props(new Actor {
    var speed = 60d
    var callback: (String) => Unit = { (output) => }

    def receive = {
      case Go(command)   =>
        runningTasks += command
        if (runningTasks.size == 1) self ! Loop
      case Stop(command) =>
        runningTasks -= command
      case Loop          =>
        // In case halt is called in the middle of the loop, we need to keep
        // checking the current reference of runningTasks
        var i = 0
        while (i < runningTasks.size) {
          callback(execute("observer", runningTasks.toSeq(i)))
          i += 1
        }
        if (runningTasks.nonEmpty)
          Akka.system.scheduler.scheduleOnce((1d / speed).seconds) { self ! Loop }
      case SetOutputCallback(callback) =>
        this.callback = callback 

    }

  }))

  def go(command: String) { looper ! Go(command) }

  def stop(command: String) { looper ! Stop(command) }

  def setOutputCallback(callback: (String) => Unit) { 
    looper ! SetOutputCallback(callback)
  }

  private case class Go(command: String)
  private case class Stop(command: String)
  private case object Loop
  private case class SetOutputCallback(callback: (String) => Unit)

  abstract override def halt() {
    runningTasks = ListSet()
    super.halt()
  }
}

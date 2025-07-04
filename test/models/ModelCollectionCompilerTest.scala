package models

import java.io.File

import scala.io.Source
import scala.concurrent.duration.DurationInt

import akka.actor.{ ActorSystem, Props }
import akka.testkit.{ TestActorRef, TestKitBase, TestProbe }

import org.scalatest.{ Assertions, OneInstancePerTest }
import org.scalatest.flatspec.AnyFlatSpec

import play.api.Mode

class ModelCollectionCompilerSpec extends AnyFlatSpec with AkkaTestHelper with TestKitBase with OneInstancePerTest {

  import ModelCollectionCompiler.CheckBuiltInModels
  import StatusCacher.AllBuiltInModels

  val modelsCollection = new NetLogoModelCollection {
    override def allModels(implicit mode: Mode): Seq[File] = Seq(OilCartel, TeamAssembly, BirdBreeder).map(_.file)
  }

  lazy val observer = genInbox
  val collectionCompiler = TestActorRef(Props(classOf[ModelCollectionCompiler], () => modelsCollection.allModels(using Mode.Test), observer.ref))

  it should "send an AllModels message with a list of all files" in {
    collectionCompiler ! CheckBuiltInModels
    assertInboxReceivedInOrder(observer, AllBuiltInModels(modelsCollection.allModels(using Mode.Test)))
  }

  // If this test fails, perhaps Oil Cartel now compiles (because HubNet is
  // supported)? --Jason B. (2/5/17)
  it should "send a status update message with the compilation status of each file" in {
    collectionCompiler ! CheckBuiltInModels
    assertInboxReceivedUnordered(
      observer, 1,
      CompilationSuccess(TeamAssembly.file) == _,
      CompilationSuccess(BirdBreeder.file) == _,
      failureForTestSource(OilCartel.file)
    )
  }

  it should "shut down all children after the messages have been processed" in {
    collectionCompiler ! CheckBuiltInModels
    skipMessages(observer, 4)
    within(StandardDuration) { assert(collectionCompiler.children.isEmpty) }
  }

}

trait AkkaTestHelper extends Assertions {

  self: TestKitBase =>

  override implicit val system: ActorSystem = ActorSystem("TestActorSystem")

  class TestSource(val path: String) {
    def file:     File   = new File(path)
    def contents: String = Source.fromFile(file).mkString
  }

  val OilCartel    = new TestSource("public/modelslib/Sample Models/Social Science/Economics/Oil Cartel HubNet.nlogox")
  val TeamAssembly = new TestSource("public/modelslib/Sample Models/Networks/Team Assembly.nlogox")
  val Scatter      = new TestSource("public/modelslib/Sample Models/Social Science/Scatter.nlogox")
  val BirdBreeder  = new TestSource("public/modelslib/Curricular Models/BEAGLE Evolution/Bird Breeder.nlogox")

  val StandardDuration = 4000.millis

  val skipMessages = receiveMessagesCount

  def receiveMessagesCount(i: TestProbe, count: Int): Seq[Any] =
    Seq.fill(count)(i.receiveOne(StandardDuration))

  def failureForTestSource(sourceFile: File)(message: Any): Boolean =
    message match {
      case CompilationFailure(file, _) => file == sourceFile
      case _                           => false
    }

  def assertInboxReceivedUnordered(i: TestProbe, skip: Int, messageMatchers: (Any => Boolean)*): Unit = {
    skipMessages(i, skip)
    val receivedMessages = receiveMessagesCount(i, messageMatchers.length)
    messageMatchers.foreach(matchingMessage => assert(receivedMessages.exists(matchingMessage)))
  }

  def assertInboxReceivedInOrder(i: TestProbe, messages: Any*): Unit = {
    skipMessages(i, 0)
    messages.foreach(message => assertResult(message)(i.receiveOne(StandardDuration)))
  }

  // I do this because the tests will otherwise intermittently cause `ClassCastException`s, thanks to this bug:
  // https://github.com/akka/akka/issues/15409 .  It seems to just be a timing issue, so let's be the little train
  // that could and just keep on a-tryin'! --Jason B. (11/11/14)
  @annotation.tailrec
  final protected def genInbox(implicit system: ActorSystem): TestProbe =
    try TestProbe()(using system)
    catch {
      case ex: ClassCastException => genInbox
    }

}

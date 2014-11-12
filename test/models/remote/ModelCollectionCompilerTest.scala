package models.remote

import
  java.io.File

import
  scala.{ io => sio, concurrent },
    concurrent.duration.DurationInt,
    sio.Source

import
  akka.{ actor, testkit },
    actor.{ ActorDSL, ActorSystem, Inbox, Props },
    testkit.{ TestActorRef, TestKitBase }

import
  org.scalatest.{ Assertions, FlatSpec, OneInstancePerTest }

import
  models.NetLogoModelCollection

class ModelCollectionCompilerSpec extends FlatSpec with AkkaTestHelper with TestKitBase with OneInstancePerTest {

  import ModelCollectionCompiler.CheckBuiltInModels
  import StatusCacher.AllBuiltInModels

  val modelsCollection = new NetLogoModelCollection {
    override def allModels: Seq[File] = Seq(SmallWorld, TeamAssembly, BirdBreeder).map(_.file)
  }

  lazy val observer = ActorDSL.inbox // Will intermittently cause `ClassCastException`, thanks to this bug: https://github.com/akka/akka/issues/15409 --JAB (11/11/14)
  val collectionCompiler = TestActorRef(Props(classOf[ModelCollectionCompiler], modelsCollection, observer.getRef()))

  it should "send an AllModels message with a list of all files" in {
    collectionCompiler ! CheckBuiltInModels
    assertInboxReceivedInOrder(observer, AllBuiltInModels(modelsCollection.allModels.toSeq))
  }

  it should "send a status update message with the compilation status of each file" in {
    collectionCompiler ! CheckBuiltInModels
    assertInboxReceivedUnordered(
      observer, 1,
      CompilationSuccess(TeamAssembly.file) == _,
      failureForTestSource(BirdBreeder.file),
      failureForTestSource(SmallWorld.file)
    )
  }

  it should "shut down all children after the messages have been processed" in {
    collectionCompiler ! CheckBuiltInModels
    skipMessages(observer, 4)
    within(StandardDuration) { assert(collectionCompiler.children.isEmpty) }
  }

}

trait AkkaTestHelper extends Assertions {

  implicit val system = ActorSystem("TestActorSystem")

  class TestSource(val path: String) {
    def file:     File   = new File(path)
    def contents: String = Source.fromFile(file).mkString
  }

  val SmallWorld   = new TestSource("public/modelslib/Sample Models/Networks/Small Worlds.nlogo")
  val TeamAssembly = new TestSource("public/modelslib/Sample Models/Networks/Team Assembly.nlogo")
  val Scatter      = new TestSource("public/modelslib/Sample Models/Social Science/Scatter.nlogo")
  val BirdBreeder  = new TestSource("public/modelslib/Curricular Models/BEAGLE Evolution/Bird Breeder.nlogo")

  val StandardDuration = 4000.millis

  val skipMessages = receiveMessagesCount _

  def receiveMessagesCount(i: Inbox, count: Int): Seq[Any] =
    Seq.fill(count)(i.receive(StandardDuration))

  def failureForTestSource(sourceFile: File)(message: Any): Boolean =
    message match {
      case CompilationFailure(file, _) => file == sourceFile
      case _                           => false
    }

  def assertInboxReceivedUnordered(i: Inbox, skip: Int, messageMatchers: (Any => Boolean)*): Unit = {
    skipMessages(i, skip)
    val receivedMessages = receiveMessagesCount(i, messageMatchers.length)
    messageMatchers.forall(matchingMessage => receivedMessages.exists(matchingMessage))
  }

  def assertInboxReceivedInOrder(i: Inbox, messages: Any*): Unit = {
    skipMessages(i, 0)
    messages.foreach(message => assertResult(message)(i.receive(StandardDuration)))
  }

}

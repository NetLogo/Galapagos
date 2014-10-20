package models.remote

import
  org.scalatest._

import
  akka.{ actor, testkit },
    actor.{Props, ActorSystem, Inbox},
    testkit.{TestKitBase, TestActorRef, TestProbe}

import
  scala.{io, concurrent},
    io.Source,
    concurrent.duration._

import
  java.io.File,
  java.util.concurrent.TimeUnit

import
  ModelLibraryCompiler._,
  ModelLibraryCompiler.Messages._

import
  models.NetLogoModelCollection

class ModelCompilerSpec extends FlatSpec with AkkaTestHelper with OneInstancePerTest {
  val observer = probe
  val compiler = TestActorRef(Props(classOf[ModelCompiler], observer.ref))

  it should "send a success message to the watcher when the compilation works" in {
    compiler ! CompileModel(TeamAssembly.file, TeamAssembly.contents)
    observer.expectMsg(ModelCompilationSuccess(TeamAssembly.file))
  }

  it should "send a success message when scatter is compiled" in {
    compiler ! CompileModel(Scatter.file, Scatter.contents)
    observer.expectMsg(ModelCompilationSuccess(Scatter.file))
  }

  it should "send a failure message to the watcher when compilation fails" in {
    compiler ! CompileModel(SmallWorld.file, SmallWorld.contents)
    observer.expectMsgClass(classOf[ModelCompilationFailure])
  }

  it should "send a failure message to the watcher when compilation encounters an invalid widget" in {
    compiler ! CompileModel(BirdBreeder.file, BirdBreeder.contents)
    observer.expectMsgClass(classOf[ModelCompilationFailure])
  }
}

class ModelCollectionCompilerSpec extends FlatSpec with AkkaTestHelper with TestKitBase with OneInstancePerTest {
  val observer = inbox
  val modelsCollection = new NetLogoModelCollection {
    override def allModels: Seq[File] = Seq(SmallWorld, TeamAssembly, BirdBreeder).map(_.file)
  }
  val collectionCompiler = TestActorRef(Props(classOf[ModelCollectionCompiler], modelsCollection, observer.getRef()))

  it should "send an AllModels message with a list of all files" in {
    collectionCompiler ! CheckBuiltInModels
    assertInboxReceivedInOrder(observer, AllBuiltInModels(modelsCollection.allModels.toSeq))
  }

  it should "send a status update message with the compilation status of each file" in {
    collectionCompiler ! CheckBuiltInModels
    assertInboxReceivedUnordered(
      observer, 1,
      ModelCompilationSuccess(TeamAssembly.file) == _,
      failureForTestSource(BirdBreeder),
      failureForTestSource(SmallWorld)
    )
  }

  it should "shut down all children after the messages have been processed" in {
    collectionCompiler ! CheckBuiltInModels
    skipMessages(observer, 4)
    within(StandardDuration) { assert(collectionCompiler.children.isEmpty) }
  }
}

trait AkkaTestHelper extends org.scalatest.Assertions {
  class TestSource(val path: String) {
    def file: File = new File(path)
    def contents: String = Source.fromFile(file).mkString
  }

  val SmallWorld = new TestSource("public/modelslib/Sample Models/Networks/Small Worlds.nlogo")
  val TeamAssembly = new TestSource("public/modelslib/Sample Models/Networks/Team Assembly.nlogo")
  val Scatter = new TestSource("public/modelslib/Sample Models/Social Science/Scatter.nlogo")
  val BirdBreeder = new TestSource("public/modelslib/Curricular Models/BEAGLE Evolution/Bird Breeder.nlogo")

  implicit val system = ActorSystem("TestActorSystem")
  val StandardDuration = Duration(4000, TimeUnit.MILLISECONDS)

  def probe = TestProbe()

  def inbox = akka.actor.ActorDSL.inbox

  def receiveMessagesCount(i: Inbox, count: Int): Seq[Any] =
    for (messageNumber <- 1 to count) yield i.receive(StandardDuration)

  def skipMessages(i: Inbox, count: Int): Unit = receiveMessagesCount(i, count)

  def failureForTestSource(source: TestSource)(message: Any): Boolean = {
    message match {
      case ModelCompilationFailure(file, e) => file == source.file
      case _ => false
    }
  }

  def assertInboxReceivedUnordered(i: Inbox, skip: Int, messageMatchers: (Any => Boolean)*): Unit = {
    skipMessages(i, skip)
    val receivedMessages = receiveMessagesCount(i, messageMatchers.length)
    messageMatchers.forall(matchingMessage => receivedMessages.exists(matchingMessage))
  }

  def assertInboxReceivedInOrder(i: Inbox, messages: Any*): Unit =
    assertInboxReceivedInOrder(i, 0, messages: _*)

  def assertInboxReceivedInOrder(i: Inbox, skip: Int, messages: Any*): Unit = {
    skipMessages(i, skip)
    messages.foreach(message => assertResult(message)(i.receive(StandardDuration)))
  }
}

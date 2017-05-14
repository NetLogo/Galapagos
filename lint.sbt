import com.typesafe.sbt.jse.{ SbtJsEngine, SbtJsTask }
import SbtJsEngine.autoImport.JsEngineKeys._
import SbtJsTask.autoImport.JsTaskKeys._
import com.typesafe.sbt.web.Import.WebKeys.{ nodeModuleDirectories, nodeModules }
import scala.concurrent.duration.{ FiniteDuration, SECONDS }

lazy val coffeelint = taskKey[Seq[File]]("lint coffeescript files in Galapagos")

def allCoffeeSources(directories: Seq[File]): Seq[File] =
  (PathFinder(directories) ** "*.coffee").get

coffeelint := {
  val coffeeSources = allCoffeeSources(Seq((sourceDirectory in Assets).value, (sourceDirectory in TestAssets).value))
  val coffeelintConfig = baseDirectory.value / "coffeelint.json"
  val allArgs = Seq("-f", coffeelintConfig.getPath) ++ coffeeSources.map(_.getPath)
  SbtJsTask.executeJs(
    state.value,
    engineType.value,
    command.value,
    (nodeModuleDirectories in Assets).value.map(_.getPath),
    (nodeModuleDirectories in Assets).value.last / "coffeelint" / "bin" / "coffeelint",
    allArgs,
    FiniteDuration(60, SECONDS)
  )
  coffeeSources
}

coffeelint := (coffeelint dependsOn (nodeModules in Assets)).value

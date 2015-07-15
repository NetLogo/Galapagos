import com.typesafe.sbt.jse.{ SbtJsEngine, SbtJsTask }
import SbtJsEngine.autoImport.JsEngineKeys._
import SbtJsTask.autoImport.JsTaskKeys._
import com.typesafe.sbt.web.Import.WebKeys.{ nodeModuleDirectories, nodeModules }
import scala.concurrent.duration.{ FiniteDuration, SECONDS }

lazy val coffeelint = taskKey[Seq[File]]("lint coffeescript files in Galapagos")

coffeelint := {
  val assetSources = (sourceDirectory in Assets).value
  println(assetSources)
  val coffeeSources = (assetSources ** "*.coffee").get
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

coffeelint <<= coffeelint dependsOn (nodeModules in Assets)

import sbt._
import Keys._

import java.io.File
import java.net.URL

// Getting JS libraries and stylesheets

object ObtainResources {

  val obtainResources   = TaskKey[Unit]("obtain-resources", "download the JS libs and stylesheets")
  val obtainJSLibs      = TaskKey[Unit]("obtain-js-libs", "download the JS libs (i.e. jQuery)")
  val obtainStylesheets = TaskKey[Unit]("obtain-stylesheets", "download the stylesheets (i.e. Bootstrap)")

  val settings = Seq[Setting[_]](
    obtainResources := { },
    obtainResources <<=  obtainResources.dependsOn(obtainJSLibs, obtainStylesheets),
    compile in Compile <<= (compile in Compile).dependsOn(obtainResources),
    obtainJSLibs <<= (baseDirectory, streams) map { (base, s) =>
      obtain(base, s.log.info(_),
             "javascripts", ".js", Seq("underscore", "jquery", "mousetrap"))},
    obtainStylesheets <<= (baseDirectory, streams) map { (base, s) =>
      obtain(base, s.log.info(_),
             "stylesheets", ".css", Seq("bootstrap"))}
  )

  // does the real work
  private def obtain(base: File, log: String => Unit, folderName: String, fileExt: String, libNames: Seq[String]) {
    val dir           = base / "public" / folderName / "managed"
    val namePathPairs = libNames map (_ + fileExt) map (name => (name, dir / name))
    IO.createDirectory(dir)
    namePathPairs foreach {
      case (name, path) =>
        val url = "http://ccl.northwestern.edu/devel/" + name
        if(!path.exists) {
          log("downloading " + path)
          IO.download(new URL(url), path)
        }
    }
  }

}

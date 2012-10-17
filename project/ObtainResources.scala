import sbt.{ IO, Keys, Project, richFile, std, TaskKey }
import Keys.{ baseDirectory, streams }
import Project.ScopedKey
import std.TaskStreams

import java.io.File
import java.net.URL

// Getting JS libraries and stylesheets

object ObtainResources {

  // The thing that does the real work around here
  private val obtainerFunc =
    (folderName: String, fileExt: String, libNames: Seq[String]) =>
      (base: File, s: TaskStreams[ScopedKey[_]]) => {
        val dir           = base / "public" / folderName / "managed"
        val namePathPairs = libNames map (_ + fileExt) map (name => (name, dir / name))
        IO.createDirectory(dir)
        namePathPairs foreach {
          case (name, path) =>
            val url = "http://ccl.northwestern.edu/devel/" + name
            if(!path.exists) {
              s.log.info("downloading " + path)
              IO.download(new URL(url), path)
            }
        }
  }

  val obtainResources          = TaskKey[Unit]("obtain-resources", "download the JS libs and stylesheets")
  lazy val obtainResourcesTask = obtainResources.dependsOn(obtainJSLibs, obtainStylesheets)

  val obtainJSLibs          = TaskKey[Unit]("obtain-js-libs", "download the JS libs (i.e. jQuery)")
  lazy val obtainJSLibsTask =
    obtainJSLibs <<= (baseDirectory, streams) map obtainerFunc("javascripts", ".js", Seq("underscore", "jquery", "mousetrap"))

  val obtainStylesheets          = TaskKey[Unit]("obtain-stylesheets", "download the stylesheets (i.e. Bootstrap)")
  lazy val obtainStylesheetsTask =
    obtainStylesheets <<= (baseDirectory, streams) map obtainerFunc("stylesheets", ".css", Seq("bootstrap"))

}
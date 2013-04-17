import
  sbt._,
    Keys._

import
  java.{ io, net },
    io.File,
    net.URL

// Getting JS libraries and stylesheets

object ObtainResources {

  val obtainResources   = TaskKey[Unit]("obtain-resources",   "download the JS libs and stylesheets")
  val obtainJSLibs      = TaskKey[Unit]("obtain-js-libs",     "download the JS libs (i.e. jQuery)")
  val obtainStylesheets = TaskKey[Unit]("obtain-stylesheets", "download the stylesheets (i.e. Bootstrap)")

  val settings = Seq[Setting[_]](
    obtainResources := { },
    obtainResources <<= obtainResources.dependsOn(obtainJSLibs, obtainStylesheets),
    compile in Compile <<= (compile in Compile).dependsOn(obtainResources),
    obtainJSLibs <<= (baseDirectory, streams) map { (base, s) =>
      obtain(base, s.log.info(_), "javascripts", ".js", Seq(Rsrc("underscore-1.4.2"), Rsrc("underscore-string-2.3.0"),
                                                            Rsrc("ace-6df9748a", "./ace"), Rsrc("jquery-1.8.3"),
                                                            Rsrc("mousetrap-1.1.1")))
    },
    obtainStylesheets <<= (baseDirectory, streams) map { (base, s) =>
      obtain(base, s.log.info(_), "stylesheets", ".css", Seq(Rsrc("bootstrap-1.4.0")))
    }
  )

  // does the real work
  private def obtain(base: File, log: String => Unit, folderName: String, fileExt: String, resources: Seq[Rsrc]) {
    val dir = base / "public" / folderName / "managed"
    IO.createDirectory(dir)
    resources map {
      resource =>
        val filename  = resource.filename + fileExt
        val url       = "http://ccl.northwestern.edu/devel/" + filename
        val pathParts = resource.path.split('/').toSeq
        val path      = pathParts.foldLeft(dir){ case (acc, x) => acc / x }
        IO.createDirectory(path)
        (url, path / filename)
    } foreach {
      case (url, localPath) =>
        if(!localPath.exists) {
          log("downloading " + localPath)
          IO.download(new URL(url), localPath)
        }
    }
  }

  private case class Rsrc(filename: String, path: String = ".")

}

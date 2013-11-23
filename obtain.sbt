val obtainStylesheets =
  taskKey[Seq[File]]("download stylesheets (for e.g. Bootstrap)")

compile in Compile := {
  val _ = obtainStylesheets.value
  (compile in Compile).value
}

obtainStylesheets := {
  obtain(
    baseDirectory.value / "public" / "stylesheets" / "managed",
    streams.value.log.info(_),
    Seq("bootstrap-1.4.0.css"))
}

def obtain(dir: File, log: String => Unit, names: Seq[String]): Seq[File] = {
  IO.createDirectory(dir)
  for (name <- names)
  yield {
    val url = "http://ccl.northwestern.edu/devel/" + name
    val localPath = dir / name
    if(!localPath.exists) {
      log("downloading " + localPath)
      IO.download(new java.net.URL(url), localPath)
    }
    localPath
  }
}

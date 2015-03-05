package models

import java.io.File

trait NetLogoModelCollection {
  def allModels: Seq[File]
}

object ModelsLibrary extends NetLogoModelCollection {

  private val ModelLibRelativePath = "public/modelslib/"
  private val ModelDirectories     = Seq("Sample Models", "Code Examples", "Curricular Models", "test/benchmarks")

  def prettyFilepath(s: String): String =
    s.stripPrefix(ModelLibRelativePath).stripSuffix(".nlogo")

  def prettyFilepath(f: File): String =
    prettyFilepath(f.getPath)

  override def allModels: Seq[File] =
    ModelDirectories.
      flatMap(dir => recursivelyListFiles(new File(ModelLibRelativePath, dir))).
      filter(isNetLogoFile)

  private def isNetLogoFile(f: File): Boolean =
    f.getName.endsWith(".nlogo")

  private def recursivelyListFiles(f: File): Seq[File] = {
    val myFiles = f.listFiles
    myFiles ++ myFiles.filter(_.isDirectory).flatMap(recursivelyListFiles)
  }

}

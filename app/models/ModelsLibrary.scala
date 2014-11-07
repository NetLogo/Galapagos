package models

import
  java.io.File

trait NetLogoModelCollection {
  def allModels: Seq[File]
}

object ModelsLibrary extends NetLogoModelCollection {
  protected val ModelLibRelativePath = "public/modelslib/"
  protected val ModelDirectories = Seq("test/benchmarks", "Sample Models", "Code Examples", "Curricular Models")

  def prettyFilepath(s: String): String = s.stripPrefix(ModelLibRelativePath).stripSuffix(".nlogo")

  def prettyFilepath(f: File): String = prettyFilepath(f.getPath)

  override def allModels: Seq[File] = {
    ModelDirectories.
      flatMap(dir => recursivelyListFiles(new File(ModelLibRelativePath, dir))).
      filter(isNetLogoFile)
  }

  private def isNetLogoFile(f: File): Boolean = f.getName.endsWith(".nlogo")

  private def recursivelyListFiles(f: File): Seq[File] = {
    val myFiles = f.listFiles
    myFiles ++ myFiles.filter(_.isDirectory).flatMap(recursivelyListFiles)
  }
}

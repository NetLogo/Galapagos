// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models

import java.io.File

import
  play.api.Mode

trait NetLogoModelCollection {
  def allModels: Seq[File]
}

object ModelsLibrary extends NetLogoModelCollection {

  private val DemoModelsRelativePath = "public/demomodels/"

  private val ModelLibRelativePath   = "public/modelslib/"

  private val ModelDirectories     = Seq("Sample Models", "Code Examples", "Curricular Models", "test/benchmarks")

  def prettyFilepath(s: String): String =
    s.stripSuffix(".nlogo")

  def prettyFilepath(f: File): String =
    prettyFilepath(f.getPath)

  override def allModels: Seq[File] =
    if(play.api.Play.maybeApplication.exists(_.mode == Mode.Dev))
      modelLibraryFiles ++ demoModelFiles
    else
      modelLibraryFiles

  private lazy val demoModelFiles =
    recursivelyListFiles(new File(DemoModelsRelativePath)).filter(isNetLogoFile)

  private lazy val modelLibraryFiles =
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

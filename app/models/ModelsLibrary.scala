// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models

import java.io.File

import play.api.Mode

trait NetLogoModelCollection {
  def allModels(implicit mode: Mode): Seq[File]
}

object ModelsLibrary extends NetLogoModelCollection {

  private val DemoModelsRelativePath = "public/demomodels/"

  private val ModelLibRelativePath   = "public/modelslib/"

  private val ModelDirectories     = Seq("Sample Models", "Code Examples", "IABM Textbook", "Curricular Models", "Alternative Visualizations")

  def prettyFilepath(s: String): String =
    s.stripSuffix(".nlogo")

  def prettyFilepath(f: File): String =
    prettyFilepath(f.getPath)

  override def allModels(implicit mode: Mode): Seq[File] =
    if (mode == Mode.Dev)
      modelLibraryFiles ++ demoModelFiles
    else
      modelLibraryFiles

  private lazy val demoModelFiles =
    Seq(new File(DemoModelsRelativePath), new File(ModelLibRelativePath, "test/benchmarks"))
      .flatMap(allNetLogoFilesIn)

  private lazy val modelLibraryFiles =
    ModelDirectories.
      flatMap(dir => allNetLogoFilesIn(new File(ModelLibRelativePath, dir)))

  private def isNetLogoFile(f: File): Boolean =
    f.getName.endsWith(".nlogo")

  private def allNetLogoFilesIn(f: File): Seq[File] = {
    def recursivelyListFiles(f: File): Seq[File] = {
      val childFiles = f.listFiles
      childFiles ++ childFiles.filter(_.isDirectory).flatMap(recursivelyListFiles)
    }
    recursivelyListFiles(f).filter(isNetLogoFile)
  }
}

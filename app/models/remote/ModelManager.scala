package models.remote

import
  java.io.{ File, FilenameFilter }

/**
 * Created with IntelliJ IDEA.
 * User: jason
 * Date: 2/25/13
 * Time: 1:39 PM
 */

object ModelManager {

  private lazy val ModelFileExt    = ".nlogo"
  private lazy val ModelsPath      = "public/models/"
  private lazy val ModelsDir       = new File(ModelsPath)
  private lazy val ModelFileFilter = new FilenameFilter { override def accept(dir: File, name: String) = name.endsWith(ModelFileExt) }

  def apply(name: String) : Option[File] =
    if (contains(name))
      Option(new File(ModelsPath + name + ModelFileExt))
    else
      None

  def contains(name: String) = modelNames contains name

  def modelNames : Seq[String] = ModelsDir.list(ModelFileFilter) map (_ dropRight ModelFileExt.size)

}

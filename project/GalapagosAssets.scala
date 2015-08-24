import sbt._
import Keys.target
import com.typesafe.sbt.web.Import.{ Assets, pipelineStages }
import com.typesafe.sbt.web.pipeline.Pipeline
import com.typesafe.sbt.web.PathMapping
import org.im4java.core.{ ConvertCmd, IMOperation }

object GalapagosAssets {
  lazy val generateGalapagosFavicon = taskKey[Pipeline.Stage]("generate .ico favicon (requires imageMagick)")

  lazy val settings = Seq(
    (generateGalapagosFavicon in Assets) := { (mappings: Seq[PathMapping]) =>
      val targetDir = target.value / "favicon"
      val faviconMapping = mappings.find(_._2.contains("favicon"))
      faviconMapping.map {
        case (file, path) =>
          val newPath = path.dropRight(4) + ".ico" // get rid of png, gif, &c
          val newFile = targetDir / newPath
          IO.createDirectory(newFile.getParentFile)
          val cmd = new ConvertCmd()
          val op = new IMOperation()
          op.addImage(file.getPath)
          op.addImage(newFile.getPath)
          try {
            cmd.run(op)
            (newFile -> newPath) +: (mappings.filterNot(_._2 == path))
          } catch {
            case e: org.im4java.core.CommandException =>
              val errorMessage =
                """|Unable to find ImageMagick's convert utility:
                   |Please ensure ImageMagick is installed and available on your $PATH""".stripMargin
              sys.error(errorMessage)
              mappings
          }
      }.getOrElse(mappings)
    },
    pipelineStages in Assets += (generateGalapagosFavicon in Assets))
}

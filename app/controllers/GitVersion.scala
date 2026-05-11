// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

object GitVersion {

  private def runGit(args: String*): Option[String] =
    try {
      val proc = new ProcessBuilder(("git" :: args.toList)*)  .start()
      scala.io.Source.fromInputStream(proc.getInputStream).getLines().nextOption().map(_.trim)
    } catch { case _: Exception => None }

  private def runGitLines(args: String*): List[String] =
    try {
      val proc = new ProcessBuilder(("git" :: args.toList)*).start()
      scala.io.Source.fromInputStream(proc.getInputStream).getLines().toList
    } catch { case _: Exception => Nil }

  private def runGitExitCode(args: String*): Int =
    try {
      val proc = new ProcessBuilder(("git" :: args.toList)*).start()
      proc.waitFor()
    } catch { case _: Exception => -1 }

  def commitVersion: String = {
    val commit = runGit("rev-parse", "--short", "HEAD").getOrElse("unknown")
    val dirty  = runGitExitCode("diff", "--quiet") != 0
    if (dirty) s"$commit-dirty" else commit
  }

  def releaseVersion: String =
    runGit("tag", "-l", "v*.*.*", "--sort=-v:refname")
      .map(_.stripPrefix("v"))
      .getOrElse("unknown")

  def allReleaseTags: List[String] =
    runGitLines("tag", "-l", "v*.*.*", "--sort=-v:refname")

  def commitForRef(ref: String): String =
    runGit("rev-parse", "--short", ref).getOrElse("unknown")

}

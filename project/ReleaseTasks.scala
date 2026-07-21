import sbt._
import sbt.io.IO

import scala.sys.process.{ Process, ProcessLogger }

import java.time.LocalDate
import java.time.format.DateTimeFormatter

// Local automation for the NetLogo Web release process. See the Galapagos wiki page
// "NetLogo-Web-Release-Process" for the manual steps these tasks replace. Everything here is local;
// pushing to `main`/`production` remains a deliberate manual step.
//
// The release is split into three tasks because there are two required manual pauses:
//   1. `startRelease <version>` - branch, sync the models library, bump the version, and draft the
//      release notes. Then you review/edit the drafted `whatsNew.scala.html` section by hand.
//   2. `finalizeRelease <version>` - commit those prepared changes. The commit leaves a clean repo,
//      which is required before generating the standalone HTML bundle (a dirty repo bakes a
//      `-dirty` suffix into the bundle's embedded version). Then you generate the bundle by hand.
//   3. `tagRelease <version>` - commit the generated bundle and create the `v<version>` tag.
//
// `syncModels` exposes step 1's models-library sync on its own, for prepping the library outside a
// release.
object ReleaseTasks {

  private val versionRegex   = """\d+\.\d+\.\d+""".r
  // e.g. `val tortoiseVersion = "1.0-cf53d18"`
  private val tortoiseRegex  = """(?m)^\s*val\s+tortoiseVersion\s*=\s*"([^"]+)"""".r
  // e.g. `NETLOGO_VERSION      = '2.15.1' + commitSuffix`
  private val netlogoVerRegex = """(NETLOGO_VERSION\s*=\s*')[^']*(')""".r

  private def fail(msg: String): Nothing = throw new MessageOnlyException(msg)

  // sbt doesn't reliably surface a MessageOnlyException's message in batch mode, so log it explicitly
  // (still rethrowing so the task fails). Wrap each entry-point body with this.
  private def reporting[T](log: sbt.util.Logger)(body: => T): T =
    try body
    catch { case e: MessageOnlyException => log.error(e.getMessage); throw e }

  // Discards a subprocess's stdout/stderr (e.g. the hash `git rev-parse --verify` prints on success).
  private val devNull = ProcessLogger(_ => (), _ => ())

  private def requireVersion(args: Seq[String]): String = args match {
    case Seq(v) if versionRegex.pattern.matcher(v).matches => v
    case _ => fail("Expected a single MAJOR.MINOR.PATCH version argument, e.g. `startRelease 2.15.2`.")
  }

  // --- git helpers -----------------------------------------------------------------------------

  private def gitOut(cwd: File, args: String*): String =
    Process("git" +: args, cwd).!!.trim

  private def gitLines(cwd: File, args: String*): List[String] =
    Process("git" +: args, cwd).lineStream_!.toList

  private def gitSucceeds(cwd: File, args: String*): Boolean =
    Process("git" +: args, cwd).!(devNull) == 0

  private def gitRun(log: sbt.util.Logger, cwd: File, args: String*): Unit = {
    log.info("git " + args.mkString(" "))
    val code = Process("git" +: args, cwd).!
    if (code != 0) fail(s"`git ${args.mkString(" ")}` failed with exit code $code.")
  }

  private def currentBranch(cwd: File): String =
    gitOut(cwd, "rev-parse", "--abbrev-ref", "HEAD")

  private def isClean(cwd: File): Boolean =
    gitSucceeds(cwd, "diff", "--quiet") && gitSucceeds(cwd, "diff", "--cached", "--quiet")

  private def refExists(cwd: File, ref: String): Boolean =
    gitSucceeds(cwd, "rev-parse", "-q", "--verify", ref)

  private def requireOnBranch(cwd: File, branch: String): Unit = {
    val current = currentBranch(cwd)
    if (current != branch)
      fail(s"Expected to be on branch `$branch` but on `$current`. Run `startRelease` first, or check out the release branch.")
  }

  // The most recent `v*.*.*` tag, ignoring the version we're currently releasing (in case of a re-run).
  private def previousTag(cwd: File, version: String): Option[String] =
    gitLines(cwd, "tag", "-l", "v*.*.*", "--sort=-v:refname").filter(_ != s"v$version").headOption

  // The version currently baked into session-lite.coffee's NETLOGO_VERSION assignment.
  private def currentNetlogoVersion(baseDir: File): Option[String] =
    """NETLOGO_VERSION\s*=\s*'([^']*)'""".r.findFirstMatchIn(IO.read(sessionLiteFile(baseDir))).map(_.group(1))

  // --- misc helpers ----------------------------------------------------------------------------

  private def esc(s: String): String =
    s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

  private def ordinal(n: Int): String =
    if (n >= 11 && n <= 13) "th"
    else n % 10 match {
      case 1 => "st"
      case 2 => "nd"
      case 3 => "rd"
      case _ => "th"
    }

  private def formattedToday(): String = {
    val today = LocalDate.now()
    val month = today.format(DateTimeFormatter.ofPattern("MMMM"))
    val day   = today.getDayOfMonth
    s"$month $day${ordinal(day)} ${today.getYear}"
  }

  private def sessionLiteFile(baseDir: File): File =
    baseDir / "app" / "assets" / "javascripts" / "beak" / "session-lite.coffee"

  private def whatsNewFile(baseDir: File): File =
    baseDir / "app" / "views" / "whatsNew.scala.html"

  private def bundleFile(baseDir: File, version: String): File =
    baseDir / "public" / "versions" / s"$version.html"

  // The short hash a pinned tortoise version points at, e.g. "1.0-cf53d18" -> "cf53d18".
  private def tortoiseHash(pinned: String): String =
    pinned.substring(pinned.lastIndexOf('-') + 1)

  // --- task 1: startRelease --------------------------------------------------------------------

  def start(log: sbt.util.Logger, baseDir: File, tortoiseDir: File, args: Seq[String]): Unit = reporting(log) {
    if (args.isEmpty) {
      log.info(s"Current version:    ${currentNetlogoVersion(baseDir).getOrElse("(unknown)")} (NETLOGO_VERSION in session-lite.coffee)")
      log.info(s"Latest release tag: ${previousTag(baseDir, "").getOrElse("(none)")}")
      log.info("Usage: startRelease <MAJOR.MINOR.PATCH>")
    } else {
      startRelease(log, baseDir, tortoiseDir, requireVersion(args))
    }
  }

  private def startRelease(log: sbt.util.Logger, baseDir: File, tortoiseDir: File, version: String): Unit = {
    val branch  = s"$version-release"

    if (currentBranch(baseDir) != branch) {
      if (!isClean(baseDir))
        fail(s"Working tree has uncommitted changes; commit or stash them before starting a release.")
      if (refExists(baseDir, s"refs/heads/$branch")) {
        log.info(s"Checking out existing branch `$branch`.")
        gitRun(log, baseDir, "checkout", branch)
      } else {
        log.info(s"Creating and checking out branch `$branch`.")
        gitRun(log, baseDir, "checkout", "-b", branch)
      }
    } else {
      log.info(s"Already on `$branch`; continuing (re-run).")
    }

    val syncedDirs = syncModelsLibrary(log, baseDir, tortoiseDir)
    bumpNetlogoVersion(log, baseDir, version)
    draftReleaseNotes(log, baseDir, tortoiseDir, version)

    log.info("")
    log.info(s"startRelease complete for v$version:")
    log.info(s"  branch:       $branch")
    log.info(s"  models synced: ${if (syncedDirs.isEmpty) "(none matched)" else syncedDirs.mkString(", ")}")
    log.info(s"  version bump:  NETLOGO_VERSION -> $version in session-lite.coffee")
    log.info(s"  notes draft:   inserted a DRAFT section in app/views/whatsNew.scala.html")
    log.info("")
    log.info("Next steps (manual):")
    log.info("  1. Review model library changes with `git status` / `git diff public/modelslib`.")
    log.info("  2. Edit the DRAFT section in app/views/whatsNew.scala.html: trim internal-only items,")
    log.info("     tighten wording, and remove the DRAFT markers.")
    log.info(s"""  3. Run `finalizeRelease $version` to make the release commit.""")
  }

  // --- standalone task: syncModels -------------------------------------------------------------

  // The models-library sync on its own, for prepping the library ahead of (or outside) a release.
  // `startRelease` runs the same sync as part of its sequence.
  def syncModels(log: sbt.util.Logger, baseDir: File, tortoiseDir: File): Unit = reporting(log) {
    val syncedDirs = syncModelsLibrary(log, baseDir, tortoiseDir)

    log.info("")
    if (syncedDirs.isEmpty)
      log.warn("No directories were shared between public/modelslib and Tortoise's models; nothing synced.")
    else
      log.info(s"Models synced: ${syncedDirs.mkString(", ")}")
    log.info("Review the changes with `git status` / `git diff public/modelslib`.")
  }

  // Sync each model-category directory that exists in BOTH public/modelslib and Tortoise's models
  // dir. Using the intersection keeps Tortoise-only build files (bin/, project/, build.sbt, ...) and
  // Galapagos-only files (README.md) out of the copy. `git diff` afterward shows the real changes.
  private def syncModelsLibrary(log: sbt.util.Logger, baseDir: File, tortoiseDir: File): Seq[String] = {
    val modelsLib      = baseDir / "public" / "modelslib"
    val tortoiseModels = tortoiseDir / "models"
    if (!tortoiseModels.isDirectory)
      fail(s"Tortoise models directory not found at ${tortoiseModels.getPath}. " +
           "Set `tortoiseDirectory` in build.sbt or check out the Tortoise repo as a sibling.")

    val shared = Option(modelsLib.listFiles).getOrElse(Array.empty[File])
      .filter(_.isDirectory)
      .map(_.getName)
      .filter(name => (tortoiseModels / name).isDirectory)
      .sorted

    shared.foreach { name =>
      log.info(s"Syncing models library directory: $name")
      IO.delete(modelsLib / name)
      IO.copyDirectory(tortoiseModels / name, modelsLib / name, overwrite = true, preserveLastModified = true)
    }
    shared.toSeq
  }

  private def bumpNetlogoVersion(log: sbt.util.Logger, baseDir: File, version: String): Unit = {
    val file    = sessionLiteFile(baseDir)
    val content = IO.read(file)
    if (!netlogoVerRegex.pattern.matcher(content).find())
      fail(s"Could not find NETLOGO_VERSION assignment in ${file.getPath}.")
    val updated = netlogoVerRegex.replaceFirstIn(content, "$1" + version + "$2")
    if (updated != content) {
      IO.write(file, updated)
      log.info(s"Set NETLOGO_VERSION to '$version' in session-lite.coffee.")
    } else {
      log.info(s"NETLOGO_VERSION already set to '$version'; no change.")
    }
  }

  private def draftReleaseNotes(log: sbt.util.Logger, baseDir: File, tortoiseDir: File, version: String): Unit = {
    val file    = whatsNewFile(baseDir)
    val content = IO.read(file)
    if (content.contains(s"""id="v$version"""")) {
      log.warn(s"""whatsNew.scala.html already contains a section for v$version; skipping notes draft.""")
      return
    }

    val prevTagOpt = previousTag(baseDir, version)
    prevTagOpt.foreach(t => log.info(s"Gathering Galapagos commits since $t (first-parent)."))

    // `--first-parent` gives one message per merge (the merge commit's own subject) and one per direct
    // commit, which matches "merge commits only get the merge commit message".
    val galaMsgs = prevTagOpt match {
      case Some(tag) => gitLines(baseDir, "log", "--first-parent", s"$tag..HEAD", "--pretty=format:%s").filter(_.trim.nonEmpty)
      case None =>
        log.warn("No previous v*.*.* tag found; leaving the Galapagos commit list empty.")
        Nil
    }

    val tortMsgs = tortoiseMessages(log, baseDir, tortoiseDir, prevTagOpt)

    val section = renderSection(version, galaMsgs, tortMsgs)

    val marker = "class=\"inner-content\""
    val markerIdx = content.indexOf(marker)
    if (markerIdx < 0) fail("Could not locate the `inner-content` container in whatsNew.scala.html.")
    val insertAt = content.indexOf('\n', markerIdx) + 1
    val updated  = content.substring(0, insertAt) + section + content.substring(insertAt)
    IO.write(file, updated)
    log.info(s"Inserted DRAFT release notes for v$version (${galaMsgs.size} Galapagos, ${tortMsgs.size} Tortoise items).")
  }

  private def tortoiseMessages(log: sbt.util.Logger, baseDir: File, tortoiseDir: File, prevTagOpt: Option[String]): List[String] = {
    val currPin = tortoiseRegex.findFirstMatchIn(IO.read(baseDir / "build.sbt")).map(_.group(1))
    val prevPin = prevTagOpt.flatMap { tag =>
      try tortoiseRegex.findFirstMatchIn(gitOut(baseDir, "show", s"$tag:build.sbt")).map(_.group(1))
      catch { case _: Exception => None }
    }

    (prevPin, currPin) match {
      case (Some(prev), Some(curr)) if prev != curr =>
        if (!tortoiseDir.isDirectory) {
          log.warn(s"Tortoise pin changed ($prev -> $curr) but ${tortoiseDir.getPath} is missing; add Tortoise notes manually.")
          Nil
        } else {
          log.info(s"Gathering Tortoise commits ${tortoiseHash(prev)}..${tortoiseHash(curr)} (first-parent).")
          val msgs = gitLines(tortoiseDir, "log", "--first-parent",
            s"${tortoiseHash(prev)}..${tortoiseHash(curr)}", "--pretty=format:%s").filter(_.trim.nonEmpty)
          if (msgs.isEmpty)
            log.warn("Could not read Tortoise commits for that range (are those commits present in the Tortoise repo?); add them manually if needed.")
          msgs
        }
      case (Some(_), Some(_)) =>
        log.info("Tortoise pin unchanged since the last release; no Tortoise notes to add.")
        Nil
      case _ =>
        log.warn("Could not determine the Tortoise version pin; add any Tortoise notes manually.")
        Nil
    }
  }

  private def renderSection(version: String, galaMsgs: Seq[String], tortMsgs: Seq[String]): String = {
    val sb = new StringBuilder
    sb.append("\n")
    sb.append(s"    <!-- DRAFT (v$version): review and trim before finalizing. Remove internal-only items (refactors, dep bumps) and tighten wording. Delete these DRAFT markers when done. -->\n")
    sb.append(s"""    <h2 id="v$version">${formattedToday()} - v$version</h2>\n""")
    sb.append("\n")
    sb.append("    <ul>\n")
    if (galaMsgs.isEmpty) sb.append("      <!-- No Galapagos commits found for this range. -->\n")
    galaMsgs.foreach(m => sb.append(s"      <li>${esc(m)}</li>\n"))
    sb.append("    </ul>\n")
    if (tortMsgs.nonEmpty) {
      sb.append("\n")
      sb.append("    <!-- Tortoise / engine updates: -->\n")
      sb.append("    <ul>\n")
      tortMsgs.foreach(m => sb.append(s"      <li>${esc(m)}</li>\n"))
      sb.append("    </ul>\n")
    }
    sb.append(s"    <!-- END DRAFT (v$version) -->\n")
    sb.toString
  }

  // --- task 2: finalizeRelease -----------------------------------------------------------------

  def finalizeRelease(log: sbt.util.Logger, baseDir: File, args: Seq[String]): Unit = reporting(log) {
    val version = requireVersion(args)
    requireOnBranch(baseDir, s"$version-release")

    val notes = IO.read(whatsNewFile(baseDir))
    if (!notes.contains(s"""id="v$version""""))
      fail(s"whatsNew.scala.html has no section for v$version. Run `startRelease $version` first.")
    if (notes.contains(s"DRAFT (v$version)"))
      log.warn("The DRAFT markers are still in whatsNew.scala.html. Edit/trim the notes and remove the markers before finalizing.")

    val paths = Seq(
      "app/assets/javascripts/beak/session-lite.coffee",
      "app/views/whatsNew.scala.html",
      "public/modelslib"
    )
    gitRun(log, baseDir, ("add" +: paths): _*)

    if (gitSucceeds(baseDir, "diff", "--cached", "--quiet"))
      fail("Nothing staged to commit. The release changes may already be committed.")

    gitRun(log, baseDir, "commit", "-m", s"Docs/Infrastructure: Release v$version")

    log.info("")
    log.info(s"Committed the v$version release changes. The working tree is now clean.")
    log.info("")
    log.info("Next steps (manual):")
    log.info("  1. With `sbt run` live, open http://localhost:9000/standalone?empty in a browser.")
    log.info("  2. Use Export: HTML to download the standalone bundle.")
    log.info(s"""  3. Save it as public/versions/$version.html (a clean repo avoids a `-dirty` version stamp).""")
    log.info(s"""  4. Run `tagRelease $version` to commit the bundle and tag the release.""")
  }

  // --- task 3: tagRelease ----------------------------------------------------------------------

  def tagRelease(log: sbt.util.Logger, baseDir: File, args: Seq[String]): Unit = reporting(log) {
    val version = requireVersion(args)
    requireOnBranch(baseDir, s"$version-release")

    val tag = s"v$version"
    if (refExists(baseDir, s"refs/tags/$tag"))
      fail(s"Tag $tag already exists. Delete it first if you need to re-tag.")

    val bundle = bundleFile(baseDir, version)
    if (!bundle.exists)
      fail(s"Bundle not found at public/versions/$version.html. Generate it from " +
           "http://localhost:9000/standalone?empty (Export: HTML) on a clean repo, then re-run.")

    // The bundle embeds its build's git description; a `-dirty` suffix means it was exported from a
    // dirty repo and should be regenerated. See the release-process wiki note.
    if (IO.read(bundle).contains("-dirty"))
      fail(s"public/versions/$version.html contains a `-dirty` version stamp. Regenerate it from a " +
           "clean repository (commit or stash any changes first).")

    gitRun(log, baseDir, "add", s"public/versions/$version.html")
    if (gitSucceeds(baseDir, "diff", "--cached", "--quiet"))
      fail(s"public/versions/$version.html is already committed; nothing to do but the tag is missing. Create it with `git tag $tag`.")

    gitRun(log, baseDir, "commit", "-m", s"Infrastructure: Add v$version standalone HTML bundle")
    gitRun(log, baseDir, "tag", tag)

    log.info("")
    log.info(s"Tagged $tag on the release commit. This release will now appear in /versions.json.")
    log.info("")
    log.info("Remaining manual steps:")
    log.info(s"  - Push the branch and tag when ready: `git push origin $version-release $tag` (or via your normal main/production flow).")
    log.info("  - If this release published a new Tortoise version, tag the matching commit in the Tortoise repo too.")
  }

}

#!/bin/sh
exec bin/scala -classpath bin -deprecation -nocompdaemon -Dfile.encoding=UTF-8 "$0" "$@"
!#

// When we make an incompatible change to the language, Version.isCompatibleVersion() returns false
// and we give a warning when opening or saving a model from the old version. But that we don't want
// that happening with models we release to the public, so sometimes the versions recorded in our
// model files need to be updated en masse.

import io.Source.fromFile

val version = fromFile("resources/system/version.txt").getLines.next
for(path <- args) {
  val sections = fromFile(path).mkString.split("\\@\\#\\$\\#\\@\\#\\$\\#\\@\n",-1)
  val newSections = sections.map(section => if(section.matches("NetLogo .*\n")) version + "\n"
                                            else section)
  new java.io.PrintStream(new java.io.FileOutputStream(new java.io.File(path)))
    .print(newSections.mkString("@#$#@#$#@\n"))
}

// Local Variables:
// mode: scala
// End:

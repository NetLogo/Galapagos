package models.remote.workspace

import 
  org.nlogo.{ headless, api },
    headless.HeadlessWorkspace,
    api.{ Program, Version }

import collection.immutable.ListMap

trait Compiler extends HeadlessWorkspace {

  def setActiveCode(nlogoCode: String) {
    // This is based on CompilerManager.compileAll
    // Using api.Program.empty() for the program will do it cleanly, but it
    // loses variables.

    // If we don't blank out breeds on compile, it complains about breeds
    // being redefined. However, if we just toss breeds and the currently
    // opened model has plots that use breeds, when a user deletes the breeds
    // line in the program, calling `reset-ticks` errors. As a workaround,
    // we just sneak the old breeds back in when putting results.program
    // into the world program.
    // be removed.
    val breeds = world.program.breeds
    val results = compiler.compileProgram(
      nlogoCode, world.program.copy(breeds = ListMap()), getExtensionManager)

    procedures = results.proceduresMap
    init()
    // FIXME: Global and turtle variables appear to be preserved during
    // recompile, but patch variables do not. I think this needs to be
    // fixed on the NetLogo side.
    world.rememberOldProgram()
    // world.program must be set to results.program. We sneak the old breeds
    // back in so that widgets depending on the breeds don't freakout if
    // they're not there anymore.
    world.program(results.program.copy(
      breeds = results.program.breeds ++ breeds))
    world.realloc()
  }

}

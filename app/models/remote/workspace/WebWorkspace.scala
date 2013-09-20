package models.remote.workspace

import
  org.nlogo.{ agent, api, nvm, headless, workspace },
    agent.World,
    api.{ CompilerException, LogoException, RendererInterface },
    headless.HeadlessWorkspace,
    nvm.{ CompilerInterface }

/**
  * Manages a NetLogo workspace for use in NetLogo web clients
  */

class WebWorkspace(world: World, compiler: CompilerInterface, renderer: RendererInterface)
    extends HeadlessWorkspace(world, compiler, renderer)
    with Executor
    with StateTracker
    with Compiler
    with ForeverRunner
    

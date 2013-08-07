package models.remote.workspace

import
  org.nlogo.{ agent, api, nvm, headless, workspace },
    agent.World,
    api.{ AggregateManagerInterface, CompilerException, LogoException, RendererInterface },
    headless.HeadlessWorkspace,
    nvm.{ CompilerInterface, DefaultCompilerServices },
    workspace.AbstractWorkspace.HubNetManagerFactory

/**
  * Manages a NetLogo workspace for use in NetLogo web clients
  */

class WebWorkspace(world: World, compiler: CompilerInterface, renderer: RendererInterface,
                   aggregateManager: AggregateManagerInterface, hbmFactory: HubNetManagerFactory)
    extends HeadlessWorkspace(world, compiler, renderer, aggregateManager, hbmFactory)
    with Executor
    with StateTracker
    with Compiler
    with ForeverRunner

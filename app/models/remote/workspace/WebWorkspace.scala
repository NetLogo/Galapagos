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
    with Executor {

  private var updateDisplayListeners: List[ () => Unit ] = Nil
  private var requestDisplayUpdateListeners: List[ () => Unit ] = Nil

  def addRequestDisplayUpdateListener( listener: () => Unit ) {
    requestDisplayUpdateListeners ::= listener
  }

  override def requestDisplayUpdate(context: org.nlogo.nvm.Context, force: Boolean) {
    requestDisplayUpdateListeners foreach { _() }
  }

  def addUpdateDisplayListener( listener: () => Unit ) {
    updateDisplayListeners ::= listener
  }

  override def updateDisplay(haveWorldLockAlready: Boolean) {
    updateDisplayListeners foreach { _() }
  }



}

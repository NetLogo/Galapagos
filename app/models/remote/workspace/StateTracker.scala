package models.remote.workspace

import
  org.nlogo.{ headless, mirror },
    headless.HeadlessWorkspace,
    mirror.{ Mirrorables, Mirroring, Update }

trait StateTracker extends HeadlessWorkspace {

  private var currentState: Mirroring.State = Map()
  // Calculating diffs takes a long time. This keeps track of if we actually
  // have to do it.
  private var isDirty: Boolean = false

  private def stateNeedsUpdate() { isDirty = true }

  def updatePending = isDirty
  
  /**
   * Returns the diff between the currently tracked state and the current
   * state of the workspace. Updates the currently tracked state to the
   * current state of the workspace.
   */
  def updateState(): Update = {
    // Don't calculate the diff if we don't have to
    if (updatePending) {
      val (newState, update) = getStateUpdate(currentState)
      currentState = newState
      isDirty = false
      update
    } else {
      Update(Seq(), Seq(), Seq())
    }
  }

  def getStateUpdate(baseState: Mirroring.State) : (Mirroring.State, Update)  =
    world.synchronized {
      val widgetValues = Seq() // Eventually, this might have something in it.  Nicolas currently only plans to ever use for monitor values, though --JAB (1/22/13)
      val mirrorables  = Mirrorables.allMirrorables(world, widgetValues)
      Mirroring.diffs(baseState, mirrorables)
    }

  override def requestDisplayUpdate(context: org.nlogo.nvm.Context, force: Boolean) {
    super.requestDisplayUpdate(context, force)
    stateNeedsUpdate()
  }

  override def updateDisplay(haveWorldLockAlready: Boolean) {
    super.updateDisplay(haveWorldLockAlready)
    stateNeedsUpdate()
  }
}
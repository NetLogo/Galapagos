import play.sbt.PlayRunHook

// This PlayRunHook is a small hack, so we can find out, if the app is running in development or production mode. When
// the app is running in development mode (`sbt run`), `PlayDevMode.isDevMode` returns `true`,
// otherwise it returns `false`. - David D. 7/2021
object PlayDevMode {
  private var _isDevMode = false
  
  def apply(): PlayRunHook = {
    
    object PlayDevModeHook extends PlayRunHook {
      override def beforeStarted(): Unit = _isDevMode = true
      override def afterStopped(): Unit = _isDevMode = false
    }

    PlayDevModeHook
  }
  
  def isDevMode: Boolean = _isDevMode
}

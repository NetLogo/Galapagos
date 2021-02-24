import play.sbt.PlayRunHook

// This PlayRunHook is used to detect if we're in development mode (`sbt run`).
object PlayDevMode {
  private var _isDevMode = false
  
  def apply(): PlayRunHook = {
    
    object PlayDevModeHook extends PlayRunHook {
      
      // when starting dev mode with `sbt run`, set dev mode to true
      override def beforeStarted(): Unit = _isDevMode = true

      // reset dev mode to false after stopping the dev server
      override def afterStopped(): Unit = _isDevMode = false
    }

    PlayDevModeHook
  }
  
  def isDevMode: Boolean = _isDevMode
}
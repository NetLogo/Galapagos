package models.remote

trait EventManagerProtocol {
  protected val JoinKey        = "join"
  protected val ChatterKey     = "chatter"
  protected val CommandKey     = "command"
  protected val ResponseKey    = "response"
  protected val QuitKey        = "quit"
  protected val ViewUpdateKey  = "update"
}

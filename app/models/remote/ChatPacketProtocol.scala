package models.remote

trait ChatPacketProtocol {
  protected val KindKey     = "kind"
  protected val ContextKey  = "context"
  protected val UserKey     = "user"
  protected val MembersKey  = "members"
  protected val MessageKey  = "message"
  protected val ErrorKey    = "error"
}

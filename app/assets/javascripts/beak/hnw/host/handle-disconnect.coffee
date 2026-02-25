import { runAmbiguous } from "./run.js"

# ((String) => Client, (Client) => Unit, (String) => Role, () => Session) =>
# (MessageEvent) => Unit
handleDisconnect = (getClient, unregisterClient, getRole, getSession) -> (e) ->

  id      = e.data.joinerID
  client  = getClient(id)
  session = getSession()

  if client?

    { roleName, who } = client
    role              = getRole(roleName)
    onDC              = role.onDisconnect
    afterDC           = role.afterDisconnect

    unregisterClient(id)
    session.hnw.unsubscribe(id)

    if not role.isSpectator
      turtle = world.turtleManager.getTurtle(who)

      if onDC?
        turtle.ask((-> runAmbiguous(onDC)), false)

      if not turtle.isDead()
        turtle.ask((-> SelfManager.self().die()), false)

    if afterDC?
      runAmbiguous(afterDC, who)

    session.updateWithoutRendering()

  return

export default handleDisconnect

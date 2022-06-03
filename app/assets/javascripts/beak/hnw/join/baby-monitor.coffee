import IDManager    from "../common/id-manager.js"
import MessageQueue from "../common/message-queue.js"

import applyUpdate   from "./apply-update.js"
import loadInterface from "./load-interface.js"

babyMonitor = null # MessagePort
idMan       = null # IDManager

protocolObj = { protocolVersion: "0.0.1" }

# (Object[Any], Array[MessagePort]?) => Unit
postToBM = (message, transfers = []) ->

  idObj    = { id: idMan.next("") }
  finalMsg = Object.assign({}, message, idObj, { source: "nlw-join" })

  babyMonitor.postMessage(finalMsg, transfers)

# (() => String) => (String, Object[Any]) => Unit
sendHNWPayload = (getToken) -> (type, pload) ->
  token   = getToken()
  payload = Object.assign({}, pload, { token, type }, protocolObj)
  postToBM({ type: "relay", payload })
  return

# ( () => Session, (Session) => Unit, () => Role, (String) => Unit
# , (String) => Unit, () => String, (String) => Unit) => (Object[Any]) => Unit
onBabyMonitorMessage = ( getSession, setSession, getRole, setRole
                       , setUsername, getToken, setToken) -> (data) ->
  switch data.type
    when "hnw-load-interface"
      loadInterface( getSession, setSession, setToken, setRole
                   , setUsername, sendHNWPayload(getToken))(data)

    when "nlw-append-output", "append-output"
      getSession().widgetController.appendOutput(data.output)

    when "nlw-set-output", "set-output"
      getSession().widgetController.setOutput(data.output)

    when "nlw-state-update", "nlw-apply-update"
      applyUpdate(getSession, postToBM, sendHNWPayload(getToken))(data.update)

    when "hnw-register-assigned-agent"
      loopUntilSession =
        ->
          session = getSession()
          if session?
            if data.agentType is 0
              vc = session.widgetController.viewController
              vc.highlightTurtle(data.turtleID, getRole().highlightMainColor)
          else
            setTimeout(loopUntilSession, 10)

      loopUntilSession()

    when "hnw-widget-update"
      if data.type is "ticks-started"
        getSession().widgetController.ractive.set('ticksStarted', data.event.value)
      else
        console.warn("Unknown HNW widget update type")

    else
      console.warn("Unknown baby monitor message", data.type, data)

  return

# ( () => Session, (Session) => Unit, () => Role, (String) => Unit
# , (String) => Unit, () => String, (String) => Unit) => (MessageEvent) => Unit
setUpBabyMonitor = ( getSession, setSession, getRole, setRole
                   , setUsername, getToken, setToken) -> (e) ->

  babyMonitor = e.ports[0]
  idMan       = new IDManager()

  onBM = onBabyMonitorMessage( getSession, setSession, getRole, setRole
                             , setUsername, getToken, setToken)

  msgQueue = new MessageQueue(onBM)

  babyMonitor.onmessage =
    ({ data, ports: [port] }) ->
      portObj = if port? then { port } else {}
      msg     = Object.assign({}, data, portObj)
      msgQueue.enqueue(msg)
      return

  # This message is `await`ed in the frame above.
  # It does not need an ID. --Jason B. (1/27/22)
  babyMonitor.postMessage({ type: "noop" })

  return

export default setUpBabyMonitor

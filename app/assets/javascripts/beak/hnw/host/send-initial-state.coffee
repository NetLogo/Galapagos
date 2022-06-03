import { runAmbiguous } from "./run.js"

PlotInt    = -1
SetupFlag  = 0
UpdateFlag = 1

# (Widget, String, Number, Array[P13N]) => Widget
applyP13Ns = (widget, breedName, who, personalizations) ->

  wrapIt = (code) -> "ask #{breedName} #{who} [ #{code} ]"

  w = structuredClone(widget)

  for [index, flag] in personalizations
    if index is PlotInt
      if flag is SetupFlag
        w.setupCode = wrapIt(w.setupCode)
      else
        w.updateCode = wrapIt(w.updateCode)
    else
      pen = { w.pens[index]... }
      if flag is SetupFlag
        pen.setupCode = wrapIt(pen.setupCode)
      else
        pen.updateCode = wrapIt(pen.updateCode)
      w.pens[index] = pen

  w

# ( () => Session, (Number) => Role, () => MessagePort, (String) => Array[Widget]
# , (String, Client) => Unit) => (MessageEvent) => Unit
sendInitialState = ( getSession, getRole, getBabyMonitor, getWidgetTemplates
                   , registerClient) -> (e) ->

  session = getSession()

  viewState = session.widgetController.widgets().find(({ type }) -> type is 'view')
  role      = getRole(e.data.roleIndex)

  username = e.data.username
  who      = null

  templatePairs = getWidgetTemplates(role.name)

  templates =
    if role.onConnect?
      result = runAmbiguous(role.onConnect, username)
      filled =
        if typeof result is 'number'
          who = result
          templatePairs.map(([w, ps]) -> applyP13Ns(w, role.name, who, ps))
        else
          []
      session.updateWithoutRendering()
      filled
    else
      []

  client =
    { roleName:    role.name
    , overrideVar: role.viewOverrideVar
    , perspVar:    role.perspectiveVar
    , username
    , who
    }

  registerClient(e.data.token, client)

  TurtleTypeNum   = 0
  PatchTypeNum    = 1
  LinkTypeNum     = 2
  ObserverTypeNum = 3

  agentMessage =
    if who?
      { agentType: TurtleTypeNum, turtleID: who }
    else
      { agentType: ObserverTypeNum }

  token = e.data.token

  descriptor = "Remote - #{role.name} - #{username}"
  session.hnw.subscribeWithID(null, token, descriptor, templates)

  state = session.hnw.getModelState(token)

  type        = "hnw-initial-state"
  baseMessage = { token, state, viewState, type }
  respondent  = e.ports?[0] ? getBabyMonitor()
  respondent.postMessage({ baseMessage, agentMessage })

  return

export default sendInitialState

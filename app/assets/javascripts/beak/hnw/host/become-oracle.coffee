import genUUID from "/uuid.js"

import IDManager from "../common/id-manager.js"

import { loadModel                             } from "./load-model.js"
import { runAmbiguous, runCommand, runReporter } from "./run.js"

import { ScriptSource } from "/beak/nlogo-source.js"

protocolObj = { protocolVersion: "0.0.1" }

relayIDMan = new IDManager()

# type BM     = MessagePort
# type NextID = (BM) => Number
# type P13N   = (Int, Int)

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

# (NextID, BM) => (Object[Any], Array[MessagePort]?) => Unit
postToBM = (nextID, babyMonitor) -> (message, transfers = []) ->

  idObj    = { id: nextID(babyMonitor) }
  finalMsg = Object.assign({}, message, idObj, { source: "nlw-host" })

  babyMonitor.postMessage(finalMsg, transfers)

# (NextID, BM) => (Sting, Object[Any]) => Unit
broadcastHNWPayload = (nextID, bm) -> (type, payload) ->
  truePayload = Object.assign({}, payload, { type }, protocolObj)
  postToBM(nextID, bm)({ type: "relay", payload: truePayload })
  return

# (NextID, BM) => (String, Sting, Object[Any]) => Unit
narrowcastHNWPayload = (nextID, bm) -> (uuid, type, payload) ->
  truePayload = Object.assign({}, payload, { type }, protocolObj)
  postToBM(nextID, bm)({ type: "relay", isNarrowcast: true
                       , recipient: uuid, payload: truePayload })
  return

# (NextID, BM) => (MessageEvent) => Unit
handleJoinerMsg = (nextID, bm) -> (e) ->
  switch e.data.type
    when "relay"
      id  = relayIDMan.next("")
      msg = Object.assign({}, e.data.payload, { id }, { source: "frame-relay" })
      window.postMessage(msg)
    when "hnw-fatal-error"
      postToBM(nextID, bm)(e.data)
    when "noop"
    else
      console.warn("Unknown inner joiner message:", e.data)

# (Session, Object[Any], () => Unit) => DOMElement
initUI = (session, data, notifyStopIterating) ->

  exiles =
    [ document.querySelector('.netlogo-header')
    , document.querySelector('.netlogo-display-horizontal')
    , document.querySelector('.netlogo-tab-area')
    ]

  exiles.forEach((n) -> n.classList.add("hidden"))

  flexbox    = document.createElement("div")
  flexbox.id = "main-frames-container"
  flexbox.classList.add("flex-row", "frames-container")

  wContainer = document.querySelector('.netlogo-widget-container')
  wContainer.parentNode.replaceChild(flexbox, wContainer)

  if data.onStart?
    session.widgetController.ractive.on("hnw-setup", (-> runCommand(data.onStart)))

  if data.onIterate?
    session.widgetController.ractive.on("hnw-go", (
      ->
        didStop = runCommand(data.onIterate)
        if didStop
          notifyStopIterating()
    ))

  flexbox

# (Monitor, String, Session) => Unit
registerMonitor = (monitor, roleName, session) ->

  safely = (f) -> (x) ->
    try workspace.dump(f(x))
    catch ex
      "N/A"

  func =
    switch monitor.reporterStyle

      when "global-var"
        do (monitor) -> safely(-> world.observer.getGlobal(monitor.source))

      when "procedure"
        do (monitor) -> safely(-> runReporter(monitor.source))

      when "turtle-var"
        plural = world.breedManager.getSingular(roleName).name
        do (monitor) ->
          safely(
            (who) ->
              turtle = world.turtleManager.getTurtleOfBreed(plural, who)
              turtle.getVariable(monitor.source)
          )

      when "turtle-procedure"
        plural = world.breedManager.getSingular(roleName).name
        do (monitor) ->
          safely(
            (who) ->
              turtle = world.turtleManager.getTurtleOfBreed(plural, who)
              turtle.projectionBy(-> runReporter(monitor.source))
          )

      else
        console.log("We got '#{monitor.reporterStyle}'?")

  session.hnw.registerMonitorFunc(roleName, monitor.source, func)

  return

# ( Session, DOMElement, Role, View
# , BM, (String, Client) => Unit, NextID, Number) => Unit
initSupervisorFrame = ( session, flexbox, role, baseView
                      , bm, registerClient, nextID, tickRate) ->

  frame     = document.createElement("iframe")
  frame.src = "/hnw/join"

  frame.classList.add("hnw-join-frame")
  frame.classList.add("supervisor-frame")

  title           = document.createElement("div")
  title.innerText = "Teacher"

  flex = document.createElement("div")
  flex.appendChild(title)
  flex.appendChild(frame)
  flexbox.appendChild(flex)

  frame.classList.add("supervisor-frame")
  title.classList.add("supervisor-title")
  flex .classList.add("supervisor-flex", "flex-column")

  frame.addEventListener('load', ->

    uuid = genUUID()

    wind = frame.contentWindow

    client =
      { roleName:    role.name
      , overrideVar: role.viewOverrideVar
      , perspVar:    role.perspectiveVar
      }

    registerClient(uuid, client)

    hjm = handleJoinerMsg(nextID, bm)
    session.hnw.initSamePageClient( uuid, hjm, wind, role, baseView, null, tickRate, [])

    session.widgetController.ractive.observe(
      'ticksStarted'
    , (newValue, oldValue) ->
        if (newValue isnt oldValue)
          broadcastHNWPayload(nextID, bm)("ticks-started", { value: newValue })
    )

    if role.onConnect?
      runAmbiguous(role.onConnect, "the supervisor")
      session.updateWithoutRendering()

  )

  return

# ( Session, DOMElement, Role, View, BM
# , (String, Client) => Unit, NextID, Number, Array[(Widget, Array[P13N])]) => Unit
initStudentFrame = ( session, flexbox, role, baseView, bm
                   , registerClient, nextID, tickRate, templatePairs) ->

  frame     = document.createElement("iframe")
  frame.src = "/hnw/join"

  frame.classList.add("hnw-join-frame")

  title           = document.createElement("div")
  title.innerText = "Student"

  flex = document.createElement("div")
  flex.appendChild(title)
  flex.appendChild(frame)
  flexbox.appendChild(flex)

  frame.classList.add("student-frame")
  title.classList.add("student-title")
  flex .classList.add("student-flex", "flex-column")

  frame.addEventListener('load', ->

    uuid = genUUID()

    wind = frame.contentWindow

    username = "Fake Client"
    who      = null

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

    registerClient(uuid, client)

    hjm = handleJoinerMsg(nextID, bm)
    session.hnw.initSamePageClient( uuid, hjm, wind, role, baseView, who
                                  , tickRate, templates)

  )

  return

# ( () => BM, () => Session, (Session) => Unit, (Object[Role]) => Unit
# , (String, Client) => Unit, () => Array[UUID], (String, Widget, Array[P13N]) => Unit) =>
# (MessageEvent) => Unit
becomeOracle = ( getBabyMonitor, getSession, setSession, setRoles
               , registerClient, getClientIDsWithOutput, addTemplate) -> (e) ->

  fakePlots     = []
  templatePairs = {}

  compiler       = new BrowserCompiler()
  preCompilation = compiler.fromNlogo(e.data.nlogo)

  procedures =
    if preCompilation.model.success
      compiler.listProcedures()
    else
      msg = preCompilation.model.result.map((x) -> x.message).join('\n')
      alert(new Error("Base HNW model did not compile:\n\n#{msg}"))
      []

  procEntries = Object.values(procedures).map((p) -> [p.name.toLowerCase(), p])
  procs       = Object.fromEntries(procEntries)

  findP13Ns = (w) ->

    isP13N = (name) ->
      if name is "" or procs[name]?
        name? and
          name isnt "" and
          procs[name].isUseableByTurtles and
          not procs[name].isUseableByObserver
      else
        throw new Error("Plotting setup/update procedure '#{name}' does not exist in this model")

    out = []

    if isP13N(w.setupCode)
      out.push([PlotInt, SetupFlag])
    if isP13N(w.updateCode)
      out.push([PlotInt, UpdateFlag])

    for i, pen of w.pens
      if isP13N(pen.setupCode)
        out.push([i, SetupFlag])
      if isP13N(pen.updateCode)
        out.push([i, UpdateFlag])

    out

  for role in e.data.roles
    templatePairs[role.name] = []
    for widget in role.widgets when widget.type is "hnwPlot"
      personalizations = findP13Ns(widget)
      if personalizations.length > 0
        if not role.isSpectator
          display  = "__hnw_nc_ReplaceMe_#{widget.display}"
          template = { widget..., display, type: "plot" }
          addTemplate(role.name, template, personalizations)
          templatePairs[role.name].push([template, personalizations])
        else
          # coffeelint: disable=max_line_length
          throw new Error("Role '#{role.name}' has plots that must run in the turtle context, which is impossible for a spectator role.")
          # coffeelint: enable=max_line_length
      else
        display = "__hnw_role_#{role.name}_#{widget.display}"
        fakePlots.push({ widget..., display, type: "plot" })

  loadModel(setSession)(new ScriptSource("HubNet Web", e.data.nlogo), fakePlots)

  roles = e.data.roles.reduce(((acc, role) -> acc[role.name] = role; acc), {})
  setRoles(roles)

  babyMonitor = getBabyMonitor()
  session     = getSession()
  nextID      = -> session.hnw.nextMonIDFor(babyMonitor)
  babyPost    = postToBM(nextID, babyMonitor)

  session.hnw.entwineWithIDMan(babyMonitor)

  session.initHNW()

  ractive = session.widgetController.ractive

  ractive.set("isHNW"    , true)
  ractive.set("isHNWHost", true)

  ractive.fire("unbind-keys")

  ractive.on("show", (_, title, messages, frames) ->
    babyPost({ type: "nlw-recompile-failure", messages })
    false
  )

  ractive.on("hnw-compilation-success", (_, code) ->
    babyPost({ type: "nlw-recompile-success", code })
  )

  ractive.on("hnw-narrowcast", (_, uuid, type, payload) ->
    narrowcastHNWPayload(nextID, babyMonitor)(uuid, type, payload)
  )

  ractive.on("*.append-output-text", (
    (_, output) ->
      getClientIDsWithOutput().forEach(
        (uuid) ->
          session.hnw.narrowcast(uuid, "append-output", { output })
      )
  ))

  ractive.on("*.set-output-text", (
    (_, output) ->
      getClientIDsWithOutput().forEach(
        (uuid) ->
          session.hnw.narrowcast(uuid, "set-output", { output })
      )
  ))

  onOutput =
    (newValue, oldValue, keyPath) ->
      if newValue?
        newValuesArr = newValue.split("\n")
        if newValuesArr.length > 1
          newOutputLine = newValuesArr.at(-2)
          babyPost({ type: "nlw-command-center-output", newOutputLine })

  ractive.observe("consoleOutput", onOutput)

  notifyStopIterating = -> babyPost({ type: "hnw-stop-iterating" })

  flexbox = initUI(session, e.data, notifyStopIterating)

  baseView =
    session.widgetController.widgets().find(({ type }) -> type is 'view')

  tickRate = e.data.targetFrameRate

  if e.data.targetFrameRate?
    session.hnw.setTargetFrameRate(tickRate)

  for roleName, { widgets } of roles
    for widget in widgets when widget.type is "hnwMonitor"
      registerMonitor(widget, roleName, session)

  [studentRole, supervisorRole] = findBaseRoles(Object.values(roles))

  if templatePairs[supervisorRole.name].length > 0
    throw new Error("Supervisor role cannot have turtle context plots")

  initSupervisorFrame( session, flexbox, supervisorRole, baseView
                     , babyMonitor, registerClient, nextID, tickRate)

  initStudentFrame( session, flexbox, studentRole, baseView, babyMonitor
                  , registerClient, nextID, tickRate, templatePairs[studentRole.name])

  roleInfoArr =
    Object.values(roles).map(
      (r) ->
        { name:   r.name
        , limit:  r.limit
        , config: r
        }
    )

  rolePops =
    Object.values(roles).map(
      (r) ->
        if r is studentRole or r is supervisorRole then 1 else 0
    )

  setTimeout(
    ->
      babyPost({ type: "nlw-model-code"        , code:  ractive.get('code') })
      babyPost({ type: "nlw-model-info"        , info:  ractive.get('info') })
      babyPost({ type: "hnw-role-config"       , roles: roleInfoArr         })
      babyPost({ type: "hnw-persistent-clients", pops:  rolePops            })
  , 1000)

  return

# (Array[Role]) => (Role, Role)
findBaseRoles = (roles) ->

  findStudent = (rs) ->

    scorePairs =
      rs.map(
        (r) ->

          limitScore2 = Math.min(9999, r.limit * 50)
          limitScore  = if r.limit is -1       then 10000 else limitScore2
          specScore   = if not r.isSpectator   then    50 else 1
          nameScoreS  = if r.name is "student" then  1000 else 1
          nameScoreT  = if r.name is "client"  then  1000 else 1

          [r, limitScore * specScore * nameScoreS * nameScoreT]

      )

    pickHigherScore = (acc, x) -> if x[1] >= acc[1] then x else acc

    scorePairs.reduce(pickHigherScore, [undefined, 0])[0]

  findSupervisor = (rs) ->

    scorePairs =
      rs.map(
        (r) ->

          limitScore = if r.limit is 1           then  100 else 1
          specScore  = if r.isSpectator          then   50 else 1
          nameScoreS = if r.name is "supervisor" then 1000 else 1
          nameScoreT = if r.name is "teacher"    then 1000 else 1

          [r, limitScore * specScore * nameScoreS * nameScoreT]

      )

    pickHigherScore = (acc, x) -> if x[1] >= acc[1] then x else acc

    scorePairs.reduce(pickHigherScore, [undefined, 0])[0]

  supe       = findSupervisor(roles)
  otherRoles = roles.filter((r) -> r isnt supe)

  [findStudent(otherRoles), supe]

export default becomeOracle

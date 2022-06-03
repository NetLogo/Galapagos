import genUUID from "/uuid.js"

import IDManager from "./common/id-manager.js"

AgentModel = tortoise_require('agentmodel')

# coffeelint: disable=max_line_length
# type HNWUpdate       = { chooserUpdates :: Object[Int], inputNumUpdates :: Object[Number], inputStrUpdates :: Object[String], monitorUpdates :: Object[String], plotUpdates :: PlotsUpdate, sliderUpdates :: Object[Number], switchUpdates Object[Boolean], viewUpdate :: ViewUpdate })
# type SparseHNWUpdate = # `HNWUpdate`, but all fields are optional
# type PlotsUpdate     = Object[Array[Object[Any]]]
# coffeelint: enable=max_line_length

globalEval = eval

# (PlotsUpdate) => PlotsUpdate
prunePlotsUpdate = (plotsUpdate) ->
  out = {}
  f   = ([plotName, updates]) -> if (updates ? []).length > 0 then out[plotName] = updates
  Object.entries(plotsUpdate).forEach(f)
  out

# (HNWUpdate, Number) => SparseHNWUpdate
pruneUpdate = ({ chooserUpdates = {}, inputNumUpdates = {}, inputStrUpdates = {}
               , monitorUpdates = {}, plotUpdates = {}, sliderUpdates = {}
               , switchUpdates = {}, viewUpdate = {} }) ->

  retainIff = (cond, key, value) -> if cond then { [key]: value } else {}

  prunedPlots = prunePlotsUpdate(plotUpdates)

  chooserObj  = retainIff(Object.keys( chooserUpdates).length > 0,  "chooserUpdates",  chooserUpdates)
  inputNumObj = retainIff(Object.keys(inputNumUpdates).length > 0, "inputNumUpdates", inputNumUpdates)
  inputStrObj = retainIff(Object.keys(inputStrUpdates).length > 0, "inputStrUpdates", inputStrUpdates)
  monitorObj  = retainIff(Object.keys( monitorUpdates).length > 0,  "monitorUpdates",  monitorUpdates)
  plotObj     = retainIff(Object.keys(    prunedPlots).length > 0,     "plotUpdates",     prunedPlots)
  sliderObj   = retainIff(Object.keys(  sliderUpdates).length > 0,   "sliderUpdates",   sliderUpdates)
  switchObj   = retainIff(Object.keys(  switchUpdates).length > 0,   "switchUpdates",   switchUpdates)
  viewObj     = retainIff(Object.keys(    viewUpdate ).length > 0,     "viewUpdate" ,     viewUpdate )

  Object.assign( {}, chooserObj, inputNumObj, inputStrObj, monitorObj, plotObj
               , sliderObj, switchObj, viewObj)

# (String) => (String, String)
ncPlotNameToComps = (name) ->
  c                   = "[0-9a-fA-F]"
  uuidRegex           = "#{c}{8}-#{c}{4}-#{c}{4}-#{c}{4}-#{c}{12}"
  [_, uuid, plotName] = name.match("__hnw_nc_(#{uuidRegex})_(.*)")
  [uuid, plotName]

class HNWSession

  _compilePlots:       undefined # (Array[Plot]) => Object[Any]
  _imageCache:         undefined # Object[Object[String]]
  _isCongested:        undefined # Boolean
  _lastLoopTS:         undefined # Number
  _lastPersp:          undefined # Object[(String, Agent, Number)]
  _lastTickTS:         undefined # Number
  _monitorFuncs:       undefined # Object[(Number) => String]
  _ncPlotCache:        undefined # Object[UUID, Object[Array[PlotUpdate]]
  _overrideObj:        undefined # Object[UUID, AgentModel]
  _plotUpdateCache:    undefined # Object[Object[Array[PlotUpdate]]]
  _plotIndexCache:     undefined # Object[UUID, Object[Int]]
  _portToIDMan:        undefined # Map[MessagePort, IDManager]
  _subscriberObj:      undefined # Object[{ port :: MessagePort, descriptor :: String }]
  _targetFPS:          undefined # Number
  _templatedWidgetIDs: undefined # Object[UUID, Array[Number]]
  _widgetValueCache:   undefined # Object[UUID, Object[Any]]

  # (() => WidgetController, (Array[Plot]) => Object[Any])
  constructor: (@_getWC, @_compilePlots) ->
    @_imageCache         = {}
    @_isCongested        = false
    @_lastPersp          = {}
    @_monitorFuncs       = {}
    @_ncPlotCache        = {}
    @_overrideObj        = {}
    @_portToIDMan        = new Map()
    @_subscriberObj      = {}
    @_targetFPS          = 20
    @_templatedWidgetIDs = {}
    @_widgetValueCache   = { me: {} }

  # () => Unit
  init: ->
    @_initPlotCache()
    return

  # () => Boolean
  isHNW: ->
    @_getWC().ractive.get('isHNW') is true

  # () => Boolean
  isHost: ->
    @isHNW() and @_getWC().ractive.get('isHNWHost') is true

  # () => Boolean
  isJoiner: ->
    @isHNW() and @_getWC().ractive.get('isHNWJoiner') is true

  # () => Number
  updateDelay: ->
    1000 / @_targetFPS

  # () => Unit
  go: ->
    ractive = @_getWC().ractive
    if @isHNW() and ractive.get("isHNWTicking")
      ractive.fire("hnw-go")
    return

  # (Number) => Unit
  updateLoopTime: (time) ->
    if @isHost()
      @_lastLoopTS = time
    return

  # (Number) => Unit
  updateTickTime: (time) ->
    if @isHost()
      @_lastTickTS = time
    return

  # (Number) => (Boolean, Boolean)
  checkTickability: (time) ->

    loopElapsed    = time - (@_lastLoopTS ? 0)
    tickElapsed    = time - (@_lastTickTS ? 0)
    loopInterval   = 1000 / 20
    targetInterval = 1000 / @_targetFPS

    isOK = not @_isCongested

    mayLoop = (not @_lastLoopTS?) or           (loopElapsed >   loopInterval)
    mayTick = (not @_lastTickTS?) or (isOK and (tickElapsed > targetInterval))

    [mayLoop, mayTick]

  # () => Boolean
  shouldUpdate: ->

    wc = @_getWC()

    for _, { overrideVar, roleName, who } of wc.ractive.get('hnwClients')
      if overrideVar?

        plural     = world.breedManager.getSingular(roleName).name
        projection = -> SelfManager.self().getVariable(overrideVar)
        turtle     = world.turtleManager.getTurtleOfBreed(plural, who)
        overrides_ = turtle.projectionBy(projection)

        if overrides_.length > 0
          return true

    false

  # (MessagePort, String) => Unit
  subscribe: (babyMonitor, descriptor) ->
    uuid                = genUUID()
    @_overrideObj[uuid] = new AgentModel()
    @_subscriberObj[uuid] = { port: babyMonitor, descriptor }
    @entwineWithIDMan(babyMonitor)
    return

  # (MessagePort, String, String, Array[Widget]) => Unit
  subscribeWithID: (babyMonitor, id, descriptor, templates) ->
    @_overrideObj[     id] = new AgentModel()
    @_subscriberObj[   id] = { port: babyMonitor, descriptor }
    @_plotIndexCache[  id] = @_genPlotIndexInit(id)
    @_widgetValueCache[id] = {}
    @_ncPlotCache[     id] = {}
    @_initTemplatedWidgets(id, templates)
    return

  # (String) => Unit
  unsubscribe: (id) ->
    delete @_overrideObj[     id]
    delete @_plotIndexCache[  id]
    delete @_subscriberObj[   id]
    delete @_widgetValueCache[id]
    delete @_ncPlotCache[     id]
    @_teardownTemplatedWidgets(id)
    return

  # (String) => HNWUpdate
  getModelState: (uuid) ->

    widgetController = @_getWC()

    { drawingEvents, links, observer, patches, turtles, world: w } =
      widgetController.viewController.model

    trueObserver = Object.assign({}, observer)

    trueObserver.targetAgent = observer.targetagent
    delete trueObserver.targetagent

    trueObserver.followRadius = observer.followradius
    delete trueObserver.followradius

    devs       = @_handleImageCache(drawingEvents)
    viewUpdate = { drawingEvents: devs, links, observer: { 0: trueObserver }
                 , patches, turtles, world: { 0: w } }

    if uuid?
      Object.assign({ viewUpdate }, @_getWidgetUpdatesFor(uuid))
    else
      { viewUpdate }

  # (String, String, (Number) => String) => Unit
  registerMonitorFunc: (roleName, src, func) ->
    mfs   = @_monitorFuncs[roleName] ? {}
    newMF = { [src.toLowerCase()]: func }
    @_monitorFuncs[roleName] = Object.assign({}, mfs, newMF)
    return

  # (UUID) => Object[String]
  _widgetValuesFor: (uuid, type) ->

    out = {}

    ractive = @_getWC().ractive
    client  = ractive.get('hnwClients')[uuid]

    if client.roleName?

      { roleName, who } = client
      role              = ractive.get('hnwRoles')[roleName]

      widgetToPair =
        (isChooser) -> (widget) ->

          varName = widget.variable

          value =
            if role.isSpectator
              world.observer.getGlobal("__hnw_#{role.name}_#{varName}")
            else
              world.turtleManager.getTurtle(who).getVariable(varName)

          trueValue =
            if isChooser
              widget.choices.findIndex((x) -> x is value)
            else
              value

          [varName, trueValue]

      pairs =
        switch type
          when "chooser"
            role.widgets.filter((w) -> w.type is "hnwChooser").map(widgetToPair(true))
          when "input-num"
            boxTypes = ["Color", "Number"]
            role.widgets.filter(
              (w) -> w.type is "hnwInputBox" and w.boxedValue.type in boxTypes
            ).map(widgetToPair(false))
          when "input-str"
            boxTypes = ["String", "String (reporter)", "String (commands)"]
            role.widgets.filter(
              (w) -> w.type is "hnwInputBox" and w.boxedValue.type in boxTypes
            ).map(widgetToPair(false))
          when "monitor"
            for key, func of @_monitorFuncs[roleName]
              [key, if who? then func(who) else func()]
          when "slider"
            role.widgets.filter((w) -> w.type is "hnwSlider").map(widgetToPair(false))
          when "switch"
            role.widgets.filter((w) -> w.type is "hnwSwitch").map(widgetToPair(false))
          else
            console.warn("Unknown widget sync type", type)

      pairs?.forEach(
        ([key, value]) =>
          if @_widgetValueCache[uuid][key] isnt value
            @_widgetValueCache[uuid][key] = value
            out[key] = value
      )

    out

  # (Number) => Unit
  setTargetFrameRate: (@_targetFPS) ->
    return

  # () => Unit
  disableCongestionControl: ->
    @_isCongested = false
    return

  # () => Unit
  enableCongestionControl: ->
    @_isCongested = true
    return

  # (String) => ViewUpdate.Observer
  _genPerspUpdate: (uuid) ->

    agentToInt = tortoise_require('engine/core/agenttoint')

    ractive = @_getWC().ractive

    { perspVar, roleName, who } = ractive.get('hnwClients')[uuid]

    if perspVar?

      isSpec = ractive.get('hnwRoles')[roleName].isSpectator

      persp =
        if not isSpec
          plural     = world.breedManager.getSingular(roleName).name
          projection = -> SelfManager.self().getVariable(perspVar)
          world.turtleManager.getTurtleOfBreed(plural, who).projectionBy(projection)
        else
          world.observer.getGlobal("__hnw_#{roleName}_#{perspVar}")

      lastPersp  = @_lastPersp[uuid]
      isSame     = lastPersp?                 and
                     persp[0] is lastPersp[0] and
                     persp[1] is lastPersp[1] and
                     persp[2] is lastPersp[2]

      if Array.isArray(persp) and (not isSame)

        @_lastPersp[uuid]      = persp
        [type, target, radius] = persp

        if not type?
          [{ perspective: 0 }]
        else
          [{
            followRadius: radius
            perspective:  if type is "follow" then 2 else 3
            targetAgent:  [agentToInt(target), target.id]
          }]

      else
        {}

    else
      {}

  # (ViewUpdate, UUID) => ViewUpdate
  _genOverrideUpdate: (baseUpdate = {}, uuid) ->

    widgetController = @_getWC()
    vcAgentModel     = widgetController.viewController.model

    convertKey = (k) ->
      switch k
        when "color", "directed?", "heading", "hidden?", "label", "label-color"
           , "pcolor", "pen-mode", "pen-size", "plabel", "pxcor", "pycor"
           , "plabel-color", "shape", "size", "thickness", "tie-mode"
           , "xcor", "ycor" then k
        else
          console.error("Invalid view override key", k)
          ""

    isSimpleResetAgent = (x) ->
      x.length is 3 and
        (x[0] is "reset") and
        (isTurtle(x[1]) or isPatch(x[1]) or isLink(x[1])) and
        (typeof x[2] is "string")

    isSimpleResetAgentset = (x) ->
      x.length is 3 and
        (x[0] is "reset") and
        x[1].shufflerator? and
        (typeof x[2] is "string")

    isAgentOverride = (x) ->
      x.length is 3 and
        (isTurtle(x[0]) or isPatch(x[0]) or isLink(x[0])) and
        (typeof x[1] is "string") and
        (typeof x[2] is "function")

    isAgentsetOverride = (x) ->
      x.length is 3 and
        x[0].shufflerator? and
        (typeof x[1] is "string") and
        (typeof x[2] is "function")

    isLink = (x) ->
      x.constructor.name is "Link"

    isPatch = (x) ->
      x.constructor.name is "Patch"

    isTurtle = (x) ->
      x.constructor.name is "Turtle"

    performSimpleReset = (agents, key) =>

      trueKey = convertKey(key)

      for agent in agents

        cache = @_overrideObj[uuid] ? {}

        agentTypeKey =
          if      isTurtle(agent) then "turtles"
          else if isPatch( agent) then "patches"
          else if isLink(  agent) then   "links"
          else
            console.error("Unknown agent in simple reset", agent)
            ""

        path = [agentTypeKey, agent.id, trueKey]

        # It's possible that the agentset contains new (non-overridden) agents,
        # so we can't just blindly replace the override --Jason (1/16/23)
        if pathExists(cache)(path)
          shouldBe = readPath(cache)(path)
          writePath(outAgentModel)(path)(shouldBe)
          deletePath(cache)(path)

    performOverrides = (agents, key, lambda) =>

      trueKey = convertKey(key)

      for agent in agents

        if not agent.isDead()

          res =
            agent.projectionBy(->
              self = SelfManager.self()
              lambda(self)
            )

          cache = @_overrideObj[uuid] ? {}

          agentTypeKey =
            if      isTurtle(agent) then "turtles"
            else if isPatch( agent) then "patches"
            else if isLink(  agent) then   "links"
            else
              console.error("Unknown agent in override", agent)
              ""

          path    = [agentTypeKey, agent.id, trueKey]
          wouldBe = readPath(vcAgentModel)(path)
          writePath(cache)(path)(wouldBe)
          writePath(outAgentModel)(path)(res)

    readPath = (agentModel) -> (path) ->
      p   = path.slice(0)
      out = agentModel
      while p.length > 0
        out = out?[p.shift()] ? undefined
      out

    pathExists = (agentModel) -> (path) ->
      p         = path.slice(0)
      model     = agentModel
      doesExist = true
      while p.length > 0 and doesExist
        k = p.shift()
        if model?[k]?
          model = model[k]
        else
          doesExist = false
      doesExist

    deletePath = (agentModel) -> (path) ->

      p = path.slice(0)

      lens = agentModel

      while p.length > 1
        key  = p.shift()
        if lens[key]?
          lens = lens[key]

      if p.length is 1 and lens[p[0]]?
        delete lens[p[0]]

      return

    writePath = (agentModel) -> (path) -> (x) ->

      p = path.slice(0)

      lens = agentModel

      while p.length > 1
        key  = p.shift()
        if not lens[key]?
          lens[key] = {}
        lens = lens[key]

      if p.length is 1
        lens[p[0]] = x

      return

    copy = (agentModel) ->

      out = new AgentModel()

      out.update(agentModel)

      for k, link of agentModel.links
        if link.WHO is -1
          out.links[k] = link

      for k, turtle of agentModel.turtles
        if turtle.WHO is -1
          out.turtles[k] = turtle

      out

    { overrideVar, roleName, who } = widgetController.ractive.get('hnwClients')[uuid]

    if overrideVar?

      plural     = world.breedManager.getSingular(roleName).name
      projection = -> SelfManager.self().getVariable(overrideVar)
      turtle     = world.turtleManager.getTurtleOfBreed(plural, who)
      overrides_ = turtle.projectionBy(projection)

      if overrides_.length > 0

        outAgentModel = copy(baseUpdate)

        overrides = []

        while (overrides_.length > 0)
          overrides.push(overrides_.shift())

        for override in overrides

          if override is "reset-all"
            cached = @_overrideObj[uuid] ? {}
            outAgentModel.update(cached)
            @_overrideObj[uuid] = {}

          else if isSimpleResetAgent(override)
            [_, agent, key] = override
            performSimpleReset([agent], key)

          else if isSimpleResetAgentset(override)
            [_, agentset, key] = override
            performSimpleReset(agentset.toArray(), key)

          else if isAgentOverride(override)
            [agent, key, lambda] = override
            performOverrides([agent], key, lambda)

          else if isAgentsetOverride(override)
            [agentset, key, lambda] = override
            performOverrides(agentset.toArray(), key, lambda)

          else
            console.error("Invalid view override", override)

        if outAgentModel.observer?
          outAgentModel.observer = { 0: outAgentModel.observer }

        if outAgentModel.world?
          outAgentModel.world = { 0: outAgentModel.world }

        outAgentModel

      else
        baseUpdate

    else
      baseUpdate

  # (Object[Object[Any]]) => Object[Object[Any]]
  _handleImageCache: (drawingUpdates) ->

    hashStr = (str) ->
      hash = 0
      for i in [0...str.length]
        char  = str.charCodeAt(i)
        hash  = ((hash << 5) - hash) + char
        hash |= 0 # toInt
      hash

    drawingUpdates.map(
      (du) =>
        if du.type is "import-drawing"
          hash = hashStr(du.imageBase64)
          @_imageCache[hash] = du.imageBase64
          { type: "import-drawing-raincheck", hash, x: du.x, y: du.y }
        else
          du
    )

  # (String) => String
  cashRainCheckFor: (id) ->
    @_imageCache[id]

  # (String, String, Object[Any]) => Unit
  narrowcast: (uuid, type, data) ->
    babyMonitor = @_subscriberObj[uuid].port
    if Object.keys(data).length > 0
      if babyMonitor isnt null
        @_postOnPort(babyMonitor, Object.assign({}, data, { type }))
      else
        @_getWC().ractive.fire("hnw-narrowcast", uuid, type, data)
    return

  # (String, String, Object[Any]) => Unit
  narrowcastUpdate: (uuid, type, update) ->
    if Object.keys(update).length > 0
      @narrowcast(uuid, type, { update })
    return

  # (MessagePort) => Number
  nextMonIDFor: (port) ->
    @_portToIDMan.get(port).next("")

  # (MessagePort) => Unit
  entwineWithIDMan: (babyMonitor) ->
    @_portToIDMan.set(babyMonitor, new IDManager())
    return

  # ( UUID, (Object[Any]) => Unit, Window, Object[Any], Object[Any], Number
  # , Number, Array[Widget]) => Unit
  initSamePageClient: ( uuid, onMsg, cWindow, role, baseView, who
                      , tickRate, templates) ->

    channel                    = new MessageChannel
    innerBabyMonitor           = channel.port1
    innerBabyMonitor.onmessage = onMsg

    cWindow.postMessage({ type: "hnw-set-up-baby-monitor" }, "*", [channel.port2])

    descriptor = "Same-Page Client - #{role.name}"

    @subscribeWithID(innerBabyMonitor, uuid, descriptor, templates)
    @entwineWithIDMan(innerBabyMonitor)

    @_postOnPort(innerBabyMonitor, {
      type:     "hnw-load-interface"
    , role:     role
    , tickRate
    , token:    uuid
    , view:     baseView
    }, [(new MessageChannel).port2])

    @_postOnPort(innerBabyMonitor, {
      type:   "nlw-state-update"
    , update: @getModelState(uuid)
    })

    if who?
      @_postOnPort(innerBabyMonitor, {
        type: "hnw-register-assigned-agent"
      , agentType: 0
      , turtleID:  who
      })

    return

  # (MessagePort, Object[Any], Array[MessagePort]?) => Unit
  _postOnPort: (port, message, transfers = []) ->

    id       = @_portToIDMan.get(port)?.next("")
    idObj    = if id? then { id } else {}
    finalMsg = Object.assign({}, message, idObj, { source: "interframe" })

    port.postMessage(finalMsg, transfers)

    return

  # (BrowserCompiler) => Unit
  updateMetadata: (compiler) ->

    widgetController = @_getWC()

    ractive = widgetController.ractive

    if @isHNW() and ractive.get('isEditing')

      ractive.set('metadata.globalVars', compiler.listGlobalVars())
      ractive.set('metadata.procedures', compiler.listProcedures())

      baseMetadata = ractive.get('metadata')

      elems = Array.from(document.getElementById('config-frames').children)

      for frame in elems when frame.dataset.roleName?
        roleName = frame.dataset.roleName
        itsVars  = compiler.listVarsForBreed(roleName)
        metadata = Object.assign({}, baseMetadata, { myVars: itsVars })
        frame.contentWindow.postMessage({ metadata, type: "update-metadata" }, "*")

    return

  # (UUID) => (String, Any) => Unit
  updateWidgetCache: (uuid) => (varName, value) =>
    if varName?
      if @_widgetValueCache[uuid][varName] isnt value
        @_widgetValueCache[uuid][varName] = value
    return

  # (Object[Any]) => Unit
  performUpdate: (diffedUpdate) ->

    if Object.keys(@_subscriberObj).length > 0

      if @isHost()
        @_performHostUpdate(diffedUpdate)
      else if @isJoiner()

        wc = @_getWC()

        wc.widgets().forEach(
          (w) =>

            [type, varName, value] =
              switch w.type
                when "hnwChooser"
                  ["chooser", w.variable, w.currentChoice + 1]
                when "hnwInputBox"
                  ["inputBox", w.variable, w.currentValue]
                when "hnwSlider"
                  ["slider", w.variable, w.currentValue]
                when "hnwSwitch"
                  ["switch", w.variable, w.currentValue]
                else
                  [null, null, null]

            if varName?
              if @_widgetValueCache["me"][varName] isnt value
                @_widgetValueCache["me"][varName] = value
                wup = { type, varName, value }
                wc.ractive.fire("hnw-send-to-host", "hnw-widget-message", wup)

        )

    return

  # (Object[Any]) => Unit
  _performHostUpdate: (diffedUpdate) ->

    widgetController = @_getWC()

    joinerDrawings =
      if (diffedUpdate.drawingEvents ? []).length > 0
        { drawingEvents: @_handleImageCache(diffedUpdate.drawingEvents) }
      else
        {}

    joinerUpdate = Object.assign({}, diffedUpdate, joinerDrawings)

    ticks = joinerUpdate?.world?[0]?.ticks ? null

    vupdate = pruneUpdate({ viewUpdate: joinerUpdate })

    @_pushToPlotCache(widgetController.getPlotUpdates())

    for uuid, entry of @_subscriberObj

      wupdates    = @_getWidgetUpdatesFor(uuid)
      update      = pruneUpdate(wupdates)
      perspUpdate = @_genPerspUpdate(uuid)

      overrideUpdate = @_genOverrideUpdate(vupdate.viewUpdate, uuid)

      if Object.keys(overrideUpdate).length > 0
        update.viewUpdate = overrideUpdate

      if Object.keys(perspUpdate).length > 0
        update.viewUpdate          = update.viewUpdate ? {}
        update.viewUpdate.observer = perspUpdate

      if Object.keys(update).length > 0
        babyMonitor = entry.port
        if babyMonitor isnt null
          @_postOnPort(babyMonitor, { update, type: "nlw-state-update" })
        else
          widgetController.ractive.fire( "hnw-narrowcast", uuid
                                       , "nlw-state-update", { update })

    return

  # (String) => HNWUpdate
  _getWidgetUpdatesFor: (uuid) ->

    widgetController = @_getWC()

    chooserUpdates  = @_widgetValuesFor(uuid,   "chooser")
    inputNumUpdates = @_widgetValuesFor(uuid, "input-num")
    inputStrUpdates = @_widgetValuesFor(uuid, "input-str")
    monitorUpdates  = @_widgetValuesFor(uuid,   "monitor")
    sliderUpdates   = @_widgetValuesFor(uuid,    "slider")
    switchUpdates   = @_widgetValuesFor(uuid,    "switch")

    plotUpdates = @_pullFromPlotCache(uuid)

    { chooserUpdates, inputNumUpdates, inputStrUpdates, monitorUpdates
    , plotUpdates, sliderUpdates, switchUpdates }

  # () => Unit
  _initPlotCache: ->

    @_plotIndexCache  = {}
    @_plotUpdateCache = {}

    roles = @_getWC().ractive.get("hnwRoles")

    for roleName, { widgets } of roles
      plotNames    = widgets.filter((w) -> w.type is "hnwPlot").map((p) -> p.display)
      initialState = plotNames.reduce(((acc, x) -> acc[x] = []; acc), {})
      @_plotUpdateCache[roleName] = initialState

    return

  # (UUID) => Object[Number]
  _genPlotIndexInit: (uuid) ->

    ractive = @_getWC().ractive
    client  = ractive.get('hnwClients')[uuid]

    if client.roleName?
      { roleName, who } = client
      role              = ractive.get('hnwRoles')[roleName]
      plots             = role.widgets.filter((w) -> w.type is "hnwPlot")
      Object.fromEntries(plots.map((p) -> [p.display, -1]))
    else
      throw new Error("Invalid client ID for plot cache init")

  # (PlotsUpdate) => Unit
  _pushToPlotCache: (plotUpdates) ->

    process = (v, plotName) ->
      update = { v... }
      if update.type is "reset"
        update.plot = { update.plot..., name: plotName }
      update

    for k, vs of plotUpdates

      if k.startsWith("__hnw_role_")
        [_, roleName, plotName] = k.match(/__hnw_role_([^_]+)_(.*)/)
        for v in vs
          update = process(v, plotName)
          @_plotUpdateCache[roleName][plotName].push(update)

      else if k.startsWith("__hnw_nc_")
        [uuid, plotName] = ncPlotNameToComps(k)
        for v in vs
          update = process(v, plotName)
          @_ncPlotCache[uuid][plotName].push(update)

    return

  # (UUID) => PlotsUpdate
  _pullFromPlotCache: (uuid) ->

    out = {}

    indexCache = @_plotIndexCache[uuid]

    ractive = @_getWC().ractive
    client  = ractive.get('hnwClients')[uuid]

    if client.roleName?

      { roleName } = client
      role         = ractive.get('hnwRoles')[roleName]

      plots     = role.widgets.filter((w) -> w.type is "hnwPlot")
      plotNames = plots.map((p) -> p.display)

      for plotName in plotNames
        if @_ncPlotCache[uuid][plotName]?
          out[plotName]                 = @_ncPlotCache[uuid][plotName]
          @_ncPlotCache[uuid][plotName] = []
        else
          updates   = @_plotUpdateCache[role.name][plotName]
          lastIndex = indexCache[plotName]
          if (updates.length - 1) > lastIndex
            out[plotName]        = updates.slice(lastIndex + 1)
            indexCache[plotName] = updates.length - 1

    else
      throw new Error("Invalid client ID for plot cache pull")

    out

  # (String, Array[Widget]) => Unit
  _initTemplatedWidgets: (id, templates) ->
    @_templatedWidgetIDs[id] = []
    for t in templates
      if t.type is "plot"

        filledName    = t.display.replace("ReplaceMe", id)
        filled        = { t..., display: filledName }
        compilation   = @_compilePlots([filled])

        if compilation.success

          wid = @_getWC().createPlot(filled)
          @_templatedWidgetIDs[id].push(wid)

          [_, plotName]               = ncPlotNameToComps(filledName)
          @_ncPlotCache[id][plotName] = []

          js = """(function() {
  #{compilation.result}
  return modelConfig.plots;
})();
"""

          oldPlots = modelConfig.plots
          newPlots = globalEval(js)
          plot = newPlots.reverse().find((p) -> p.name is filledName)

          modelConfig.plots = oldPlots.concat([plot])
          plotManager.addPlot(plot)
          plot.setup()

        else
          console.error("A plot template failed to compile", compilation)

      else
        console.warn("Cannot instantiate widget template of type '#{t.type}'.")

    return

  # (String) => Unit
  _teardownTemplatedWidgets: (id) ->
    @_templatedWidgetIDs[id].forEach(
      (wid) =>
        name = @_getWC().ractive.get('widgetObj')[wid].display
        plotManager.removePlot(name)
        @_getWC().removeWidgetById(wid, true)
    )
    return

export default HNWSession

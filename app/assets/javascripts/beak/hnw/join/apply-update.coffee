import { findBaddie } from "./validate-message.js"

cachedDrawings = {}

# ((String, Object[Any]) => Unit) => (Array[DrawingEvent]) => Array[DrawingEvent]
preprocessDrawingEvents = (sendPayload) -> (drawingEvents) ->

  checkIsMajorDrawingEvent =
    (x) ->
      x.type in ["import-drawing-raincheck", "import-drawing", "clear-drawing"]

  desWithIndices = drawingEvents.map((de, i) -> [de, i])

  lastDrawingIndex =
    desWithIndices.reduce(
      ((acc, [de, i]) -> if checkIsMajorDrawingEvent(de) then i else acc)
    , -1)

  realDrawings =
    drawingEvents.filter(
      (de) ->
        (not checkIsMajorDrawingEvent(de)) or (de is drawingEvents[lastDrawingIndex])
    )

  realDrawings.reduce(
    (acc, x) ->
      switch x.type
        when "import-drawing"
          cachedDrawings[x.hash] = x.imageBase64
          acc.concat([x])
        when "import-drawing-raincheck"
          if cachedDrawings[x.hash]?
            event = { type: "import-drawing", imageBase64: cachedDrawings[x.hash], x: x.x, y: x.y }
            acc.concat(event)
          else
            sendPayload("hnw-cash-raincheck", { hash: x.hash, x: x.x, y: x.y })
            acc
        else
          acc.concat([x])
  , [])

# (ViewController, (Object[Any]) => Unit, (String, Object[Any]) => Unit) =>
# (ViewUpdate) => Unit
applyViewUpdate = (viewController, postToBM, sendPayload) -> (viewUpdate) ->

  { turtles = {}, patches = {}, links = {}, drawingEvents = [] } = viewUpdate

  baddie = findBaddie(turtles, patches, links, viewController.model)

  if not baddie?
    trueDrawings = preprocessDrawingEvents(sendPayload)(drawingEvents)
    trueUpdate   = Object.assign(viewUpdate, { drawingEvents: trueDrawings })
    viewController.applyUpdate(trueUpdate)
    viewController.repaint()
  else
    msg = { type:      "hnw-fatal-error"
          , subtype:   "unknown-agent"
          , agentType: baddie[0]
          , agentID:   baddie[1][0]
          }
    postToBM(msg)

  return

# (() => Session, (Object[Any]) => Unit, (String, Object[Any]) => Unit) =>
# (Object[Any]) => Unit
applyUpdate = (getSession, postToBM, sendPayload) -> (update) ->

  session = getSession()

  if session?

    { chooserUpdates, inputNumUpdates, inputStrUpdates, monitorUpdates
    , plotUpdates, sliderUpdates, switchUpdates, viewUpdate } = update

    if viewUpdate?.world?[0]?.ticks?
      world.ticker.reset()
      world.ticker.importTicks(viewUpdate.world.ticks)

    session.widgetController.applyChooserUpdates(  chooserUpdates)
    session.widgetController.applyInputNumUpdates(inputNumUpdates)
    session.widgetController.applyInputStrUpdates(inputStrUpdates)
    session.widgetController.applyMonitorUpdates(  monitorUpdates)
    session.widgetController.applyPlotUpdates(        plotUpdates)
    session.widgetController.applySliderUpdates(    sliderUpdates)
    session.widgetController.applySwitchUpdates(    switchUpdates)

    if viewUpdate?
      viewController = session.widgetController.viewController
      applyViewUpdate(viewController, postToBM, sendPayload)(viewUpdate)

  return

export default applyUpdate

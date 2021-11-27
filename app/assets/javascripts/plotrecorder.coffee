PenBundle  = tortoise_require('engine/plot/pen')
PlotOps    = tortoise_require('engine/plot/plotops')

# type PlotEvent = { type: String, * }

class window.PlotRecorder

  _events: undefined # Array[PlotEvent]

  constructor: ->
    @_events = []

  # () => Array[PlotEvent]
  pullRecordedEvents: ->
    out = @_events
    @_events = []
    out

  # (Plot) => Unit
  recordReset: (plot) ->
    @_events.push({ type: "reset", plot })
    return

  # (Pen) => Unit
  recordRegisterPen: (pen) ->
    @_events.push({ type: "register-pen", pen: { name: pen.name, color: pen.getColor(), type: pen.getDisplayMode() } })
    return

  # (Pen) => Unit
  recordResetPen: (pen) ->
    @_events.push({ type: "reset-pen", penName: pen.name })
    return

  # (Pen, Number, Number) => Unit
  recordAddPoint: (pen, x, y) ->
    @_events.push({ type: "add-point", penName: pen.name, x, y })
    return

  # (Number, Number, Number, Number) => Unit
  recordResize: (xMin, xMax, yMin, yMax) ->
    @_events.push({ type: "resize", xMin, xMax, yMin, yMax })
    return

  # (Pen, String) => Unit
  recordUpdatePenMode: (pen, modeString) ->
    @_events.push({ type: "update-pen-mode", penName: pen.name, mode: modeString })
    return

  # (Pen, Number) => Unit
  recordUpdatePenColor: (pen, color) ->
    @_events.push({ type: "update-pen-color", penName: pen.name, color })
    return

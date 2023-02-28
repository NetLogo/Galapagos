import { cloneWidget } from "/beak/widgets/widget-properties.js"

{ fold } = tortoise_require('brazier/maybe')
{ createExportValue } = tortoise_require('engine/core/world/export')
{ Perspective } = tortoise_require('engine/core/observer')

# This class is meant to be a one-stop shop for any and all model or session related data.  The idea is that people
# embedding models or using NLW models in another application have an easy way to pull information out without having to
# know where to go to get everything.  It also means we don't have to constantly pass a `session`, `workspace`, and/or
# `widgetController` around everywhere, just this class needs them.

# This is a good companion to the event listeners, allowing data to be queried in response to model actions.

# Another good companion class would be a command executor that could make changes to a running model, but that is a
# *TODO* for later.

# -Jeremy B February 2023

class ModelOracle
  constructor: (@session, @workspace) ->
    @_exportValue = createExportValue(@workspace.world)

  # (Array[String], Array[String] | undefined) => Array[String]
  _filterNames: (names, maybeFilter) ->
    filteredNames = if maybeFilter?
      names.filter( (name) -> maybeFilter.includes(name) )
    else
      names

  # () => String
  getCode: () ->
    @session.getCode()

  # () => String | null
  getCurrentPlot: () ->
    currentPlot = fold( () -> null )( (p) -> p.name )(@workspace.plotManager.getCurrentPlotMaybe())
    currentPlot

  # () => Perspective
  getCurrentPerspective: () ->
    observer           = @workspace.world.observer
    targetAgent        = observer._targetAgent
    perspectiveType    = observer.getPerspective()
    currentPerspective = {
      type: if perspectiveType? then Perspective.perspectiveToString(perspectiveType) else 'unset'
      targetAgent: if targetAgent? then targetAgent.toString() else 'nobody'
    }
    currentPerspective

  # (Array[String] | undefined) => Array[{ name: String, value: Any }]
  getGlobals: (names) ->
    observer    = @workspace.world.observer
    globalNames = @_filterNames(observer.varNames(), names)
    globals = globalNames.map( (global) => {
      name:  global
    , value: @_exportValue(observer.getGlobal(global))
    })
    globals

  # () => String
  getInfo: () ->
    info = @session.getInfo()
    info

  # () => String
  getModelTitle: () ->
    title = @session.modelTitle()
    title

  # () => String
  getNlogo: () ->
    nlogo = @session.getNlogo()
    nlogo

  # () => NlogoSource
  getSource: () ->
    source = @session.nlogoSource
    source

  # () => Number
  getSpeed: () ->
    speed = @session.widgetController.speed()
    speed

  # () => Number | ""
  getTicks: () ->
    ticks = @session.widgetController.ractive.get('ticks')
    ticks

  # () => String
  getView: () ->
    base64 = @workspace.importExportPrims.exportViewRaw()
    base64

  # () => Array[Widget]
  getWidgets: () ->
    widgets = @session.widgetController.widgets().map(cloneWidget)
    widgets

  # (String) => Result[Any]
  runReporter: (code) ->
    result = @session.runReporter(code)

    if result.success
      result.value = @_exportValue(result.value)

    result

createModelOracle = (session, workspace) ->
  new ModelOracle(session, workspace)

export { createModelOracle }

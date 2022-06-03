# (() => WidgetController) => (MessageEvent) => Unit
applyUpdate = (getWidgetController) -> (e) ->

  wc = getWidgetController()

  { chooserUpdates, inputNumUpdates, inputStrUpdates, plotUpdates, sliderUpdates
  , switchUpdates, viewUpdate } = e.data.update

  if viewUpdate?.world?[0]?.ticks?
    world.ticker.reset()
    world.ticker.importTicks(viewUpdate.world.ticks)

  session.widgetController.applyChooserUpdates(  chooserUpdates)
  session.widgetController.applyInputNumUpdates(inputNumUpdates)
  session.widgetController.applyInputStrUpdates(inputStrUpdates)
  session.widgetController.applyPlotUpdates(        plotUpdates)
  session.widgetController.applySliderUpdates(    sliderUpdates)
  session.widgetController.applySwitchUpdates(    switchUpdates)

  if viewUpdate?
    wc.viewController.applyUpdate(viewUpdate)

  return

export default applyUpdate

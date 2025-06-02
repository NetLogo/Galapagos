{ fold } = tortoise_require('brazier/maybe')

{ DisplayMode: { displayModeToString }
, PenMode:     { penModeToBool       } } = tortoise_require('engine/plot/pen')

# (ExportedPlotManager, Array[Plot], Object[String], String, String) => ExportedPlotManager
mangleExportedPlots = (epm, plotArr, renames, oldPlotName, newPlotName) ->

  eq    = (x, y) -> x.toUpperCase() is y.toUpperCase()
  clone = window.structuredClone ? (x) -> JSON.parse(JSON.stringify(x))

  { currentPlotNameOrNull: cpnon, plots } = clone(epm)

  newCPNON =
    if cpnon? and eq(cpnon, oldPlotName)
      newPlotName
    else
      cpnon

  reverseRenames =
    Object.fromEntries(
      Object.entries(renames).map(([k, v]) -> [v, k])
    )

  for plot in plotArr

    targetName =
      if eq(plot.name, newPlotName)
        oldPlotName
      else
        plot.name

    target = plots.find((p) -> eq(p.name, targetName))

    if target?

      cpm = plot.getCurrentPenMaybe()

      target.currentPenNameOrNull = fold(-> null)((p) -> p.name)(cpm)
      target.name                 = plot.name
      target.isAutoPlotX          = plot.isAutoPlotX
      target.isAutoPlotY          = plot.isAutoPlotY
      target.isLegendOpen         = plot.isLegendEnabled

      pens = plot.getPens()

      for pen in pens

        tpName =
          if eq(plot.name, newPlotName) and reverseRenames[pen.name]?
            reverseRenames[pen.name]
          else
            pen.name

        tp = target.pens.find((p) -> eq(p.name, tpName))

        if tp?
          tp.color     = pen.getColor()
          tp.interval  = pen.getInterval()
          tp.isPenDown = penModeToBool(pen.getPenMode())
          tp.mode      = displayModeToString(pen.getDisplayMode())
          tp.name      = pen.name
          # Do not clobber the `points`!  That's the only thing that the exported
          # state gets right! --Jason B. (5/21/22)

      validPenNames = pens.map((p) -> p.name)
      target.pens   = target.pens.filter((p) -> validPenNames.includes(p.name))

  { currentPlotNameOrNull: newCPNON, plots }

export default mangleExportedPlots

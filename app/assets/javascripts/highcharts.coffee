PenBundle  = tortoise_require('engine/plot/pen')
PlotOps    = tortoise_require('engine/plot/plotops')

# (String, Plot) => Object[Any]
basicConfig = (elemID, plot) -> {
  chart: {
    animation: false,
    renderTo:  elemID,
    spacingBottom: 10,
    spacingLeft: 15,
    spacingRight: 15,
    zoomType:  "xy"
  },
  boost: {
    pixelRatio: 0,
    useGPUTranslations: true
  },
  credits: { enabled: false },
  legend:  {
    enabled: plot.isLegendEnabled,
    margin: 5,
    itemStyle: { fontSize: "10px" }
  },
  series:  [],
  title:   {
    text: plot.name,
    style: { fontSize: "12px" }
  },
  exporting: {
    buttons: {
      contextButton: {
        height: 10,
        symbolSize: 10,
        symbolStrokeWidth: 1,
        symbolY: 5
      }
    }
  }
  tooltip: {
    formatter: ->
      x = Number(Highcharts.numberFormat(@point.x, 2, '.', ''))
      y = Number(Highcharts.numberFormat(@point.y, 2, '.', ''))
      "<span style='color:#{@series.color}'>#{@series.name}</span>: <b>#{x}, #{y}</b><br/>"
  },
  xAxis: {
    title: {
      text:  plot.xLabel,
      style: { fontSize: '10px' }
    },
    labels: {
      style: { fontSize: '9px' }
    }
  },
  yAxis: {
    title: {
      text:  plot.yLabel,
      x:     -7,
      style: { fontSize: '10px' }
    },
    labels: {
      padding: 0,
      x:       -15,
      style:   { fontSize: '9px' }
    }
  },
  plotOptions: {
    series: {
      turboThreshold: 1
    },
    column: {
      pointPadding: 0,
      groupPadding: 0,
      shadow:       false,
      grouping:     false
    }
  }
}

class HighchartsOps extends PlotOps

  _chart:              undefined # Highcharts.Chart
  _penNameToSeriesNum: undefined # Object[String, Number]
  _needsRedraw:        true

  constructor: (elemID) ->

    resize = (xMin, xMax, yMin, yMax) ->
      @_chart.xAxis[0].setExtremes(xMin, xMax, false)
      @_chart.yAxis[0].setExtremes(yMin, yMax, false)
      @_needsRedraw = true
      return

    reset = (plot) ->
      @_chart.destroy()
      @_chart = new Highcharts.Chart(basicConfig(elemID, plot))
      @_penNameToSeriesNum = {}
      @_needsRedraw = true
      return

    registerPen = (pen) ->
      num    = @_chart.series.length
      series = @_chart.addSeries({
        color:      @colorToRGBString(pen.getColor()),
        data:       [],
        dataLabels: { enabled: false },
        name:       pen.name
      })
      type    = @modeToString(pen.getDisplayMode())
      options = thisOps.seriesTypeOptions(type, pen.getInterval())
      series.update(options, false)
      @_penNameToSeriesNum[pen.name] = num
      @_needsRedraw = true

      # ADD_POINT_HACK_1: This is a little hack to get Highcharts to handle `plot-pen-up`.  We put null values in the
      # data when it's up, but if we do that it will not "re-start" properly when `plot-pen-down` is called. So we store
      # the last up point so we can re-add it as needed to make the graph look right. -Jeremy B February 2021
      series._maybeLastUpPoint = null

      # ADD_POINT_HACK_2: Another Highcharts hack?  In my Beak UI?  You bet!  Here we track the "right-most" point added
      # for the series. If we ever happen to add a point to the left of that (meaning we're doing a scatter plot or a
      # "line drawing" plot), we enable Boost.  The Boost WebGL rendering module can only draw 1px wide lines, so we
      # only do this for this "degenerate" case where the performance of normal SVG drawing gets really bad.  We hope to
      # remove this hack and enable Boost for all line plots once the issue is resolved in Highcharts.
      # https://github.com/highcharts/highcharts/issues/11794 -Jeremy B January 2023
      series._maybeRightmostPoint = null

      return

    # This is a workaround for a bug in CS2 `@` detection: https://github.com/jashkenas/coffeescript/issues/5111
    # -Jeremy B. December 2018
    thisOps = null

    resetPen = (pen) => () =>
      thisOps._needsRedraw = true
      series = thisOps.penToSeries(pen)
      if series?
        series.setData([], false)
        # See ADD_POINT_HACK_1
        series._maybeLastUpPoint    = null
        # See ADD_POINT_HACK_2
        series._maybeRightmostPoint = null
      return

    addPoint = (pen) =>
      (x, y) =>
        # Wrong, and disabled for performance reasons --Jason B. (10/19/14)
        # color = @colorToRGBString(pen.getColor())
        # @penToSeries(pen).addPoint({ marker: { fillColor: color }, x: x, y: y })
        series = thisOps.penToSeries(pen)

        # See ADD_POINT_HACK_1
        pointY = if (pen.getPenMode() is PenBundle.PenMode.Down)
          if series._maybeLastUpPoint?
            series.addPoint(series._maybeLastUpPoint, false)
            series._maybeLastUpPoint = null
          y
        else
          series._maybeLastUpPoint = [x, y]
          null

        # See ADD_POINT_HACK_2
        isScatter = (pen.getDisplayMode() is PenBundle.DisplayMode.Point)
        if isScatter and series.options.boostThreshold isnt 1
          if not series._maybeRightmostPoint?
            series._maybeRightmostPoint = x
          else
            if x <= series._maybeRightmostPoint
              series.options.boostThreshold = 1
              series.update(series.options, false)
            else
              series._maybeRightmostPoint = x

        series.addPoint([x, pointY], false)
        thisOps._needsRedraw = true
        return

    updatePenMode = (pen) => (mode) =>
      series = thisOps.penToSeries(pen)
      if series?
        type    = thisOps.modeToString(mode)
        options = thisOps.seriesTypeOptions(type, pen.getInterval())
        series.update(options, false)
      return

    # Why doesn't the color change show up when I call `update` directly with a new
    # color (like I can with a type in `updatePenMode`)?
    # Send me an e-mail if you know why I can't do that.
    # Leave a comment on this webzone if you know why I can't do that.
    # --Jason B. (6/2/15)
    updatePenColor = (pen) => (color) =>
      hcColor = thisOps.colorToRGBString(color)
      series  = thisOps.penToSeries(pen)
      series.options.color = hcColor
      series.update(series.options, false)
      thisOps._needsRedraw = true
      return

    super(resize, reset, registerPen, resetPen, addPoint, updatePenMode, updatePenColor)
    thisOps              = this
    dummy                = { name: "New Plot" }
    @_chart              = new Highcharts.Chart(basicConfig(elemID, dummy))
    @_penNameToSeriesNum = {}
    #These pops remove the two redundant functions from the export-csv plugin
    #see https://github.com/highcharts/export-csv and
    #https://github.com/NetLogo/Galapagos/pull/364#discussion_r108308828 for more info
    #--Camden Clark (3/27/17)
    #I heard you like hacks, so I put hacks in your hacks.
    #Highcharts uses the same menuItems for all charts, so we have to apply the hack once. - JMB November 2017
    if not @_chart.options.exporting.buttons.contextButton.menuItems.popped?
      @_chart.options.exporting.buttons.contextButton.menuItems.pop()
      @_chart.options.exporting.buttons.contextButton.menuItems.pop()
      @_chart.options.exporting.buttons.contextButton.menuItems.popped = true

  # () => Unit
  dispose: ->
    @_chart.destroy()
    return

  # (PenBundle.DisplayMode) => String
  modeToString: (mode) ->
    { Bar, Line, Point } = PenBundle.DisplayMode
    switch mode
      when Bar   then 'column'
      when Line  then 'line'
      when Point then 'scatter'
      else 'line'

  # (String, Number) => Highcharts.Options
  seriesTypeOptions: (type, interval) ->
    isScatter = type is 'scatter'
    isLine    = type is 'line'
    isColumn  = type is 'column'
    {
      boostThreshold: 0, # Disables Boost, only enabled for true scatter plots (see `addPoint()`)
      marker:         { enabled: isScatter, radius: if isScatter then 1 else 4 },
      lineWidth:      if isLine then 2 else null,
      type:           if isLine then 'scatter' else type,
      pointRange:     if isColumn then interval else null,
      animation:      false,
      connectNulls:   false
    }

  # (PenBundle.Pen) => Highcharts.Series
  penToSeries: (pen) ->
    @_chart.series[@_penNameToSeriesNum[pen.name]]

  # () => Unit
  redraw: ->
    # Highcharts does a pretty good job of not doign too much work when nothing has really changed, but if we can avoid
    # any work at all, we might as well.  -Jeremy B March 2023
    if @_needsRedraw
      @_chart.redraw()
      @_needsRedraw = false
    return

  # (Number, Number) => Unit
  resizeElem: (x, y) ->
    @_chart.setSize(x, y, false)
    return

  # (String) => Unit
  setBGColor: (color) ->
    @_chart.chartBackground.css({ color })
    return

export default HighchartsOps

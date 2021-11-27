PenBundle  = tortoise_require('engine/plot/pen')
PlotOps    = tortoise_require('engine/plot/plotops')

# (Array[String], Object[Any]) => Object[Any]
pluck = (keys, obj) ->
  out = {}
  for key in keys
    out[key] = obj[key]
  out

class window.HighchartsOps extends PlotOps

  _chart:              undefined # Highcharts.Chart
  _penNameToSeriesNum: undefined # Object[String, Number]
  _recorder:           undefined # PlotRecorder

  constructor: (elemID) ->

    recorder = new window.PlotRecorder

    resize = (xMin, xMax, yMin, yMax) ->
      @_chart.xAxis[0].setExtremes(xMin, xMax)
      @_chart.yAxis[0].setExtremes(yMin, yMax)
      recorder.recordResize(xMin, xMax, yMin, yMax)
      return

    reset = (plot) ->
      @_chart.destroy()
      @_chart = new Highcharts.Chart({
        chart: {
          animation: false,
          renderTo:  elemID,
          spacingBottom: 10,
          spacingLeft: 15,
          spacingRight: 15,
          zoomType:  "xy"
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
            pointWidth:   8,
            borderWidth:  1,
            groupPadding: 0,
            shadow:       false,
            grouping:     false
          }
        }
      })
      @_penNameToSeriesNum = {}
      dummy = pluck(["isLegendEnabled", "name", "xLabel", "yLabel"], plot)
      recorder.recordReset(dummy)
      return

    registerPen = (pen) ->
      if not pen.getColor? # TODO: I HATE THIS --JAB (3/4/20)
        num    = @_chart.series.length
        series = @_chart.addSeries({
          color:      @colorToRGBString(0),
          data:       [],
          dataLabels: { enabled: false },
          name:       pen.name
        })
        type    = "line"
        options = thisOps.seriesTypeOptions(type)
        series.update(options)
        @_penNameToSeriesNum[pen.name] = num
      else
        num    = @_chart.series.length
        series = @_chart.addSeries({
          color:      @colorToRGBString(pen.getColor()),
          data:       [],
          dataLabels: { enabled: false },
          name:       pen.name
        })
        type    = @modeToString(pen.getDisplayMode())
        options = thisOps.seriesTypeOptions(type)
        series.update(options)
        @_penNameToSeriesNum[pen.name] = num
        recorder.recordRegisterPen(pen)
      return

    # This is a workaround for a bug in CS2 `@` detection: https://github.com/jashkenas/coffeescript/issues/5111
    # -JMB December 2018
    thisOps = null

    resetPen = (pen) => () =>
      if typeof pen is "string" # TODO: I HATE THIS --JAB (3/4/20)
        thisOps.penNameToSeries(pen)?.setData([])
      else
        thisOps.penToSeries(pen)?.setData([])
        recorder.recordResetPen(pen)
      return

    addPoint = (pen) => (x, y) =>
      # Wrong, and disabled for performance reasons --JAB (10/19/14)
      # color = @colorToRGBString(pen.getColor())
      # @penToSeries(pen).addPoint({ marker: { fillColor: color }, x: x, y: y })
      if typeof pen is "string" # TODO: I HATE THIS --JAB (3/4/20)
        thisOps.penNameToSeries(pen)?.addPoint([x, y], false)
      else
        thisOps.penToSeries(pen).addPoint([x, y], false)
        recorder.recordAddPoint(pen, x, y)
      return

    updatePenMode = (pen) => (mode) =>

      truePen = # TODO: I HATE THIS --JAB (3/4/20)
        if typeof pen is "string"
          { name: pen }
        else
          pen

      series = thisOps.penToSeries(pen)

      if series?
        type    = thisOps.modeToString(mode)
        options = thisOps.seriesTypeOptions(type)
        series.update(options)
        recorder.recordUpdatePenMode(pen, type)

      return

    # Why doesn't the color change show up when I call `update` directly with a new color
    # (like I can with a type in `updatePenMode`)?
    # Send me an e-mail if you know why I can't do that.
    # Leave a comment on this webzone if you know why I can't do that. --JAB (6/2/15)
    updatePenColor = (pen) => (color) =>
      if typeof pen is "string" # TODO: I HATE THIS --JAB (3/4/20)
        hcColor = thisOps.colorToRGBString(color)
        series  = thisOps.penNameToSeries(pen)
        series.options.color = hcColor
        series.update(series.options)
      else
        hcColor = thisOps.colorToRGBString(color)
        series  = thisOps.penToSeries(pen)
        series.options.color = hcColor
        series.update(series.options)
        recorder.recordUpdatePenColor(pen, color)
      return

    super(resize, reset, registerPen, resetPen, addPoint, updatePenMode, updatePenColor)
    thisOps              = this
    @_chart              = Highcharts.chart(elemID, {})
    @_penNameToSeriesNum = {}
    @_recorder           = recorder

    # These pops remove the two redundant functions from the export-csv plugin
    # see https://github.com/highcharts/export-csv and
    # https://github.com/NetLogo/Galapagos/pull/364#discussion_r108308828 for more info
    # --Camden Clark (3/27/17)
    #
    # I heard you like hacks, so I put hacks in your hacks.
    # Highcharts uses the same menuItems for all charts, so we have to apply the hack once. - JMB November 2017
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

  # (String) => Highcharts.Options
  seriesTypeOptions: (type) ->
    isScatter = type is 'scatter'
    isLine    = type is 'line'
    {
      marker:     { enabled: isScatter, radius: if isScatter then 1 else 4 },
      lineWidth:  if isLine then 2 else null,
      type:       if isLine then 'scatter' else type
    }

  # (PenBundle.Pen) => Highcharts.Series
  penToSeries: (pen) ->
    @penNameToSeries(pen.name)

  # (String) => Highcharts.Series
  penNameToSeries: (penName) ->
    @_chart.series[@_penNameToSeriesNum[penName]]

  # () => Array[PlotEvent]
  pullPlotEvents: ->
    @_recorder.pullRecordedEvents()

  redraw: ->
    @_chart.redraw()

  resizeElem: (x, y) ->
    @_chart.setSize(x, y, false)

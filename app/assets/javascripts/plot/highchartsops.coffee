PenBundle  = tortoise_require('engine/plot/pen')
PlotOps    = tortoise_require('engine/plot/plotops')

class window.HighchartsOps extends PlotOps

  _chart:               undefined # Highcharts.Chart
  _penNameToSeriesNum = undefined # Object[String, Number]

  constructor: (elemID) ->

    resize = (xMin, xMax, yMin, yMax) ->
      @_chart.xAxis[0].setExtremes(xMin, xMax)
      @_chart.yAxis[0].setExtremes(yMin, yMax)
      return

    reset = (plot) ->
      @_chart.destroy()
      @_chart = new Highcharts.Chart({
        chart: {
          animation: false,
          renderTo:  elemID,
          zoomType:  "xy"
        },
        legend:  { enabled: plot.isLegendEnabled, margin: 5 },
        series:  [],
        title:   { text: plot.name },
        tooltip: { pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>{point.y}</b><br/>' },
        xAxis:   { title: { text: plot.xLabel } },
        yAxis:   { title: { text: plot.yLabel } }
      })
      return

    registerPen = (pen) ->
      num = @_chart.series.length
      @_chart.addSeries({
        color:      @colorToRGBString(pen.getColor()),
        data:       [],
        dataLabels: { enabled: false },
        marker:     { enabled: false },
        name:       pen.name,
        type:       @modeToString(pen.getDisplayMode())
      })
      @_penNameToSeriesNum[pen.name] = num
      return

    resetPen = (pen) => () =>
      @penToSeries(pen)?.setData([])
      return

    addPoint = (pen) => (x, y) =>
      # color = @colorToRGBString(pen.getColor())
      # @penToSeries(pen).addPoint({ marker: { fillColor: color }, x: x, y: y }) # Wrong, and disabled for performance reasons --JAB (10/19/14)
      @penToSeries(pen).addPoint([x, y])
      return

    updatePenMode = (pen) => (mode) =>
      type   = @modeToString(mode)
      @penToSeries(pen)?.update({ type: type })
      return

    super(resize, reset, registerPen, resetPen, addPoint, updatePenMode)
    @_chart              = new Highcharts.Chart({ chart: { renderTo: elemID } })
    @_penNameToSeriesNum = {}

  # (PenBundle.DisplayMode) => String
  modeToString: (mode) ->
    { Bar, Line, Point } = PenBundle.DisplayMode
    switch mode
      when Bar   then 'bar'
      when Line  then 'line'
      when Point then 'point'
      else 'line'

  # (PenBundle.Pen) => Highcharts.Series
  penToSeries: (pen) ->
    @_chart.series[@_penNameToSeriesNum[pen.name]]

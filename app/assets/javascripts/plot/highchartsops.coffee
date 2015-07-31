PenBundle  = tortoise_require('engine/plot/pen')
PlotOps    = tortoise_require('engine/plot/plotops')

class window.HighchartsOps extends PlotOps

  _chart:              undefined # Highcharts.Chart
  _penNameToSeriesNum: undefined # Object[String, Number]

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
          zoomType:  "xy",
          spacing: [3, 3, 3, 3]
        },
        credits: { enabled: false },
        legend:  {
          enabled: plot.isLegendEnabled,
          margin: 2,
          padding: 0,
          layout: "vertical",
          verticalAlign: "middle",
          align: "right"
        },
        series:  [],
        title:   { text: plot.name, style: { fontSize: "12px" } },
        tooltip: { pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>{point.y}</b><br/>' },
        xAxis:   { title: { text: plot.xLabel } },
        yAxis:   { title: { text: plot.yLabel } },
        plotOptions: {
          series: {
            turboThreshold: 1
          },
        }
      })
      return

    registerPen = (pen) ->
      num  = @_chart.series.length
      mode = @modeToString(pen.getDisplayMode())
      @_chart.addSeries({
        color:      @colorToRGBString(pen.getColor()),
        data:       [],
        dataLabels: { enabled: false },
        marker:     { enabled: mode is 'scatter' },
        name:       pen.name,
        type:       mode
      })
      @_penNameToSeriesNum[pen.name] = num
      return

    resetPen = (pen) => () =>
      @penToSeries(pen)?.setData([])
      return

    addPoint = (pen) => (x, y) =>
      # Wrong, and disabled for performance reasons --JAB (10/19/14)
      # color = @colorToRGBString(pen.getColor())
      # @penToSeries(pen).addPoint({ marker: { fillColor: color }, x: x, y: y })
      @penToSeries(pen).addPoint([x, y], false)
      return

    updatePenMode = (pen) => (mode) =>
      type = @modeToString(mode)
      @penToSeries(pen)?.update({ type: type })
      return

    # Why doesn't the color change show up when I call `update` directly with a new color
    # (like I can with a type in `updatePenMode`)?
    # Send me an e-mail if you know why I can't do that.
    # Leave a comment on this webzone if you know why I can't do that. --JAB (6/2/15)
    updatePenColor = (pen) => (color) =>
      hcColor = @colorToRGBString(color)
      series  = @penToSeries(pen)
      series.options.color = hcColor
      series.update(series.options)
      return

    super(resize, reset, registerPen, resetPen, addPoint, updatePenMode, updatePenColor)
    @_chart              = new Highcharts.Chart({ chart: { renderTo: elemID } })
    @_penNameToSeriesNum = {}

  # (PenBundle.DisplayMode) => String
  modeToString: (mode) ->
    { Bar, Line, Point } = PenBundle.DisplayMode
    switch mode
      when Bar   then 'bar'
      when Line  then 'line'
      when Point then 'scatter'
      else 'line'

  # (PenBundle.Pen) => Highcharts.Series
  penToSeries: (pen) ->
    @_chart.series[@_penNameToSeriesNum[pen.name]]

  redraw: ->
    @_chart.redraw()

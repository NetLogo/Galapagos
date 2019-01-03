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
      options = thisOps.seriesTypeOptions(type)
      series.update(options)
      @_penNameToSeriesNum[pen.name] = num
      return

    # This is a workaround for a bug in CS2 `@` detection: https://github.com/jashkenas/coffeescript/issues/5111
    # -JMB December 2018
    thisOps = null

    resetPen = (pen) => () =>
      thisOps.penToSeries(pen)?.setData([])
      return

    addPoint = (pen) => (x, y) =>
      # Wrong, and disabled for performance reasons --JAB (10/19/14)
      # color = @colorToRGBString(pen.getColor())
      # @penToSeries(pen).addPoint({ marker: { fillColor: color }, x: x, y: y })
      thisOps.penToSeries(pen).addPoint([x, y], false)
      return

    updatePenMode = (pen) => (mode) =>
      series = thisOps.penToSeries(pen)
      if series?
        type    = thisOps.modeToString(mode)
        options = thisOps.seriesTypeOptions(type)
        series.update(options)
      return

    # Why doesn't the color change show up when I call `update` directly with a new color
    # (like I can with a type in `updatePenMode`)?
    # Send me an e-mail if you know why I can't do that.
    # Leave a comment on this webzone if you know why I can't do that. --JAB (6/2/15)
    updatePenColor = (pen) => (color) =>
      hcColor = thisOps.colorToRGBString(color)
      series  = thisOps.penToSeries(pen)
      series.options.color = hcColor
      series.update(series.options)
      return

    super(resize, reset, registerPen, resetPen, addPoint, updatePenMode, updatePenColor)
    thisOps              = this
    @_chart              = Highcharts.chart(elemID, {})
    @_penNameToSeriesNum = {}
    #These pops remove the two redundant functions from the export-csv plugin
    #see https://github.com/highcharts/export-csv and
    #https://github.com/NetLogo/Galapagos/pull/364#discussion_r108308828 for more info
    #--Camden Clark (3/27/17)
    #I heard you like hacks, so I put hacks in your hacks.
    #Highcharts uses the same menuItems for all charts, so we have to apply the hack once. - JMB November 2017
    if(not @_chart.options.exporting.buttons.contextButton.menuItems.popped?)
      @_chart.options.exporting.buttons.contextButton.menuItems.pop()
      @_chart.options.exporting.buttons.contextButton.menuItems.pop()
      @_chart.options.exporting.buttons.contextButton.menuItems.popped = true

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
    @_chart.series[@_penNameToSeriesNum[pen.name]]

  redraw: ->
    @_chart.redraw()

  resizeElem: (x, y) ->
    @_chart.setSize(x, y, false)

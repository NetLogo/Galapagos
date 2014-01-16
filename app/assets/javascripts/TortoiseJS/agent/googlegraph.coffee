window.GoogleGraph = {
  xpoint: 0
  display: "Temperature"
  drawPlot: () ->
    @chart = new google.visualization.LineChart(@graphcontainer)
    @resetData()
    setInterval(@gplot.bind(this), 100)

  resetData: () ->
    @data = new google.visualization.DataTable()
    @data.addColumn('number', 'Tick')
    @data.addColumn('number', @display)
    @data.setColumnProperty(0, 'type', 'number')
    @data.setColumnProperty(1, 'type', 'number')

    @chart.draw(@data)

  gplot: () ->
   opts = {
     backgroundColor: '#fcfdfd',
     chartArea:{width:"80%"},
     enableInteractivity: false,
     legend: {position: 'top', textStyle: {color: 'blue', fontSize: 12}, alignment:'center'}
     vAxis: {minValue: @xmin, maxValue: @xmax},
     hAxis: {minValue: @ymin, maxValue: @ymax}
   }
   @chart.draw(@data, opts)

  boot: (display, ymin, ymax, xmin, xmax, graphcontainer) ->
    @display = display
    @graphcontainer = graphcontainer
    @ymin = ymin
    @ymax = ymax
    @xmin = xmin
    @xmax = xmax
    google.load('visualization', '1', { packages:['corechart'] })
    google.setOnLoadCallback(@drawPlot.bind(this))

  plot: (y) ->
    if @xpoint % 20 == 0
      @data.addRow([@xpoint,y])
    @xpoint++

  reset: () ->
    if @data
      @data.removeRows(0, @data.getNumberOfRows())
}

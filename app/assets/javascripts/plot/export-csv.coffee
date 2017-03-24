###*
# A Highcharts plugin for exporting data from a rendered chart as CSV, XLS or HTML table
#
# Author:   Torstein Honsi
# Licence:  MIT
# Version:  1.4.7
###

###This was adapted from the following repository.
#https://github.com/highcharts/export-csv/blob/master/export-csv.js
###

###global Highcharts, window, document, Blob ###

((factory) ->
  if typeof module == 'object' and module.exports
    module.exports = factory
  else
    factory Highcharts
  return
) (Highcharts) ->

  getContent = (chart, href, extension, content, MIME) ->
    a = undefined
    blobObject = undefined
    name = undefined
    options = (chart.options.exporting or {}).csv or {}
    url = options.url or 'http://www.highcharts.com/studies/csv-export/download.php'
    if chart.options.exporting.filename
      name = chart.options.exporting.filename
    else if chart.title
      name = chart.title.textStr.replace(RegExp(' ', 'g'), '-').toLowerCase()
    else
      name = 'chart'
    # MS specific. Check this first because of bug with Edge (#76)
    if window.Blob and window.navigator.msSaveOrOpenBlob
      # Falls to msSaveOrOpenBlob if download attribute is not supported
      blobObject = new Blob([ content ])
      window.navigator.msSaveOrOpenBlob blobObject, name + '.' + extension
      # Download attribute supported
    else if downloadAttrSupported
      a = document.createElement('a')
      a.href = href
      a.target = '_blank'
      a.download = name + '.' + extension
      chart.container.append a
      # #111
      a.click()
      a.remove()
    else
      # Fall back to server side handling
      Highcharts.post url,
        data: content
        type: MIME
        extension: extension
    return

  'use strict'
  each = Highcharts.each
  pick = Highcharts.pick
  seriesTypes = Highcharts.seriesTypes
  downloadAttrSupported = document.createElement('a').download != undefined
  Highcharts.setOptions lang:
    downloadCSV: 'Download CSV'
    downloadXLS: 'Download XLS'

  ###*
  # Get the data rows as a two dimensional array
  ###

  Highcharts.Chart::getDataRows = ->
    options = (@options.exporting or {}).csv or {}
    xAxis = undefined
    xAxes = @xAxis
    rows = {}
    rowArr = []
    dataRows = undefined
    names = []
    i = undefined
    x = undefined
    xTitle = undefined
    dateFormat = options.dateFormat or '%Y-%m-%d %H:%M:%S'
    columnHeaderFormatter = options.columnHeaderFormatter or (item, key, keyLength) ->
      if item instanceof Highcharts.Axis
        return item.options.title and item.options.title.text or (if item.isDatetimeAxis then 'DateTime' else 'Category')
      if item then item.name + (if keyLength > 1 then ' (' + key + ')' else '') else 'Category'
    xAxisIndices = []
    # Loop the series and index values
    i = 0
    each @series, (series) ->
      keys = series.options.keys
      pointArrayMap = keys or series.pointArrayMap or [ 'y' ]
      valueCount = pointArrayMap.length
      requireSorting = series.requireSorting
      categoryMap = {}
      xAxisIndex = Highcharts.inArray(series.xAxis, xAxes)
      j = undefined
      # Map the categories for value axes
      each pointArrayMap, (prop) ->
        categoryMap[prop] = series[prop + 'Axis'] and series[prop + 'Axis'].categories or []
        return
      if series.options.includeInCSVExport != false and series.visible != false
        # #55
        # Build a lookup for X axis index and the position of the first
        # series that belongs to that X axis. Includes -1 for non-axis
        # series types like pies.
        if !Highcharts.find(xAxisIndices, ((index) ->
            index[0] == xAxisIndex
          ))
          xAxisIndices.push [
            xAxisIndex
            i
          ]
        # Add the column headers, usually the same as series names
        j = 0
        while j < valueCount
          names.push columnHeaderFormatter(series, pointArrayMap[j], pointArrayMap.length)
          j = j + 1
        each series.points, (point, pIdx) ->
          key = if requireSorting then point.x else pIdx
          prop = undefined
          val = undefined
          j = 0
          if !rows[key]
            # Generate the row
            rows[key] = []
            # Contain the X values from one or more X axes
            rows[key].xValues = []
          rows[key].x = point.x
          rows[key].xValues[xAxisIndex] = point.x
          # Pies, funnels, geo maps etc. use point name in X row
          if !series.xAxis or series.exportKey == 'name'
            rows[key].name = point.name
          while j < valueCount
            prop = pointArrayMap[j]
            # y, z etc
            val = point[prop]
            rows[key][i + j] = pick(categoryMap[prop][val], val)
            # Pick a Y axis category if present
            j = j + 1
          return
        i = i + j
      return
    # Make a sortable array
    for x of rows
      `x = x`
      if rows.hasOwnProperty(x)
        rowArr.push rows[x]
    binding = undefined
    xAxisIndex = undefined
    column = undefined
    dataRows = [ names ]
    i = xAxisIndices.length
    while i--
      # Start from end to splice in
      xAxisIndex = xAxisIndices[i][0]
      column = xAxisIndices[i][1]
      xAxis = xAxes[xAxisIndex]
      # Sort it by X values
      rowArr.sort (a, b) ->
        a.xValues[xAxisIndex] - (b.xValues[xAxisIndex])
      # Add header row
      xTitle = columnHeaderFormatter(xAxis)
      #dataRows = [[xTitle].concat(names)];
      dataRows[0].splice column, 0, xTitle
      # Add the category column
      each rowArr, (row) ->
        category = row.name
        if !category
          if xAxis.isDatetimeAxis
            if row.x instanceof Date
              row.x = row.x.getTime()
            category = Highcharts.dateFormat(dateFormat, row.x)
          else if xAxis.categories
            category = pick(xAxis.names[row.x], xAxis.categories[row.x], row.x)
          else
            category = row.x
        # Add the X/date/category
        row.splice column, 0, category
        return
    dataRows = dataRows.concat(rowArr)
    dataRows

  ###*
  # Build a HTML table with the data
  ###

  Highcharts.Chart::getTable = (useLocalDecimalPoint) ->
    html = '<table><thead>'
    rows = @getDataRows()
    # Transform the rows to HTML
    each rows, (row, i) ->
      tag = if i then 'td' else 'th'
      val = undefined
      j = undefined
      n = if useLocalDecimalPoint then 1.1.toLocaleString()[1] else '.'
      html += '<tr>'
      j = 0
      while j < row.length
        val = row[j]
        # Add the cell
        if typeof val == 'number'
          val = val.toString()
          if n == ','
            val = val.replace('.', n)
          html += '<' + tag + ' class="number">' + val + '</' + tag + '>'
        else
          html += '<' + tag + '>' + (if val == undefined then '' else val) + '</' + tag + '>'
        j = j + 1
      html += '</tr>'
      # After the first row, end head and start body
      if !i
        html += '</thead><tbody>'
      return
    html += '</tbody></table>'
    html
  ###*
  # Get a CSV string
  ###

  Highcharts.Chart::getCSV = (useLocalDecimalPoint) ->
    csv = ''
    rows = @getDataRows()
    options = (@options.exporting or {}).csv or {}
    itemDelimiter = options.itemDelimiter or ','
    lineDelimiter = options.lineDelimiter or '\n'
    # '\n' isn't working with the js csv data extraction
    # Transform the rows to CSV
    each rows, (row, i) ->
      val = ''
      j = row.length
      n = if useLocalDecimalPoint then 1.1.toLocaleString()[1] else '.'
      while j--
        val = row[j]
        if typeof val == 'string'
          val = '"' + val + '"'
        if typeof val == 'number'
          if n == ','
            val = val.toString().replace('.', ',')
        row[j] = val
      # Add the values
      csv += row.join(itemDelimiter)
      # Add the line delimiter
      if i < rows.length - 1
        csv += lineDelimiter
      return
    csv

  ###*
  # Call this on click of 'Download CSV' button
  ###

  Highcharts.Chart::downloadCSV = ->
    csv = @getCSV(true)
    getContent this, 'data:text/csv,\ufeff' + encodeURIComponent(csv), 'csv', csv, 'text/csv'
    return

  ###*
  # Call this on click of 'Download XLS' button
  ###

  Highcharts.Chart::downloadXLS = ->
    uri = 'data:application/vnd.ms-excel;base64,'
    template = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">' + '<head><!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet>' + '<x:Name>Ark1</x:Name>' + '<x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]-->' + '<style>td{border:none;font-family: Calibri, sans-serif;} .number{mso-number-format:"0.00";}</style>' + '<meta name=ProgId content=Excel.Sheet>' + '<meta charset=UTF-8>' + '</head><body>' + @getTable(true) + '</body></html>'

    base64 = (s) ->
      window.btoa unescape(encodeURIComponent(s))
      # #50

    getContent this, uri + base64(template), 'xls', template, 'application/vnd.ms-excel'
    return


  # Add "Download CSV" to the exporting menu. Use download attribute if supported, else
  # run a simple PHP script that returns a file. The source code for the PHP script can be viewed at
  # https://raw.github.com/highslide-software/highcharts.com/master/studies/csv-export/csv.php
  if Highcharts.getOptions().exporting
    Highcharts.getOptions().exporting.buttons.contextButton.menuItems.push {
      textKey: 'downloadCSV'
      onclick: ->
        @downloadCSV()
        return

    }, {
      textKey: 'downloadXLS'
      onclick: ->
        @downloadXLS()
        return

    }
  # Series specific
  if seriesTypes.map
    seriesTypes.map::exportKey = 'name'
  if seriesTypes.mapbubble
    seriesTypes.mapbubble::exportKey = 'name'
  if seriesTypes.treemap
    seriesTypes.treemap::exportKey = 'name'
  return

# ---
# generated by js2coffee 2.2.0

!function(e){"object"==typeof exports?module.exports=e():"function"==typeof define&&define.amd?define(e):"undefined"!=typeof window?window.LabGrapher=e():"undefined"!=typeof global?global.LabGrapher=e():"undefined"!=typeof self&&(self.LabGrapher=e())}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
module.exports.numberWidthUsingFormatter = function(elem, cx, cy, fontSizeInPixels, numberStr) {
  var testSVG,
      testText,
      bbox,
      width,
      height,
      node;

  testSVG = elem.append("svg")
    .attr("width",  cx)
    .attr("height", cy)
    .attr("class", "graph");

  testText = testSVG.append('g')
    .append("text")
      .attr("class", "axis")
      .attr("x", -fontSizeInPixels/4 + "px")
      .attr("dy", ".35em")
      .attr("text-anchor", "end")
      .text(numberStr);

  node = testText.node();

  // This code is sometimes called by tests that use d3's jsdom-based mock SVG DOm, which
  // doesn't implement getBBox.
  if (node.getBBox) {
    bbox = testText.node().getBBox();
    width = bbox.width;
    height = bbox.height;
  } else {
    width = 0;
    height = 0;
  }

  testSVG.remove();
  return [width, height];
};

module.exports.axisProcessDrag = function(dragstart, currentdrag, domain) {
  var originExtent, maxDragIn,
      newdomain = domain,
      origin = 0,
      axis1 = domain[0],
      axis2 = domain[1],
      extent = axis2 - axis1;
  if (currentdrag !== 0) {
    if  ((axis1 >= 0) && (axis2 > axis1)) {                 // example: (20, 10, [0, 40]) => [0, 80]
      origin = axis1;
      originExtent = dragstart-origin;
      maxDragIn = originExtent * 0.4 + origin;
      if (currentdrag > maxDragIn) {
        change = originExtent / (currentdrag-origin);
        extent = axis2 - origin;
        newdomain = [axis1, axis1 + (extent * change)];
      }
    } else if ((axis1 < 0) && (axis2 > 0)) {                // example: (20, 10, [-40, 40])       => [-80, 80]
      origin = 0;                                           //          (-0.4, -0.2, [-1.0, 0.4]) => [-1.0, 0.4]
      originExtent = dragstart-origin;
      maxDragIn = originExtent * 0.4 + origin;
      if ((dragstart >= 0 && currentdrag > maxDragIn) || (dragstart  < 0  && currentdrag < maxDragIn)) {
        change = originExtent / (currentdrag-origin);
        newdomain = [axis1 * change, axis2 * change];
      }
    } else if ((axis1 < 0) && (axis2 < 0)) {                // example: (-60, -50, [-80, -40]) => [-120, -40]
      origin = axis2;
      originExtent = dragstart-origin;
      maxDragIn = originExtent * 0.4 + origin;
      if (currentdrag < maxDragIn) {
        change = originExtent / (currentdrag-origin);
        extent = axis1 - origin;
        newdomain = [axis2 + (extent * change), axis2];
      }
    }
  }
  newdomain[0] = +newdomain[0].toPrecision(5);
  newdomain[1] = +newdomain[1].toPrecision(5);
  return newdomain;
};

},{}],2:[function(require,module,exports){
var axis = require('./axis');
var tooltips = {
  autoscale: "Show all data (autoscale)",
  selection: "Select data for export"
};
  
module.exports = function Graph(idOrElement, options, message, tabindex) {
  var api = {},   // Public API object to be returned.

      // D3 selection of the containing DOM element the graph is placed in
      elem,

      // Regular representation of containing DOM element the graph is placed in
      node,

      // JQuerified version of DOM element
      $node,

      // Size of containing DOM element
      cx, cy,

      // Calculated padding between edges of DOM container and interior plot area of graph.
      padding,

      // Object containing width and height in pixels of interior plot area of graph
      size,

      // D3 objects representing SVG elements/containers in graph
      svg,
      vis,
      plot,
      viewbox,
      title,
      xlabel,
      ylabel,
      selectedRulerX,
      selectedRulerY,

      // Strings used as tooltips when labels are visible but are truncated because
      // they are too big to be rendered into the space the graph allocates
      titleTooltip,
      xlabelTooltip,
      ylabelTooltip,

      // Instantiated D3 scale functions
      // currently either d3.scale.linear, d3.scale.log, or d3.scale.pow
      xScale,
      yScale,

      // The approximate number of gridlines in the plot, passed to d3.scale.ticks() function
      xTickCount,
      yTickCount,

      // Instantiated D3 line function: d3.svg.line()
      line,

      // numeric format functions wrapping the d3.format() functions
      fx,
      fy,

      // Instantiated D3 numeric format functions: d3.format()
      fx_d3,
      fy_d3,

      // Function for stroke styling of major and minor grid lines
      gridStroke = function(d) { return d ? "#ccc" : "#666"; },

      // Functions for translation of grid lines and associated numeric labels
      tx = function(d) { return "translate(" + xScale(d) + ",0)"; },
      ty = function(d) { return "translate(0," + yScale(d) + ")"; },

      // Div created and placed with z-index above all other graph layers that holds
      // graph action/mode buttons.
      buttonLayer,
      selectionButton,

      // Div created and placed with z-index under all other graph layers
      background,

      // Optional string which can be displayed in background of interior plot area of graph.
      notification,

      // An array of strings holding 0 or more lines for the title of the graph
      titles = [],

      // D3 selection containing canvas
      graphCanvas,

      // HTML5 Canvas object containing just plotted lines
      gcanvas,
      gctx,
      canvasFillStyle = "rgba(255,255,255, 0.0)",

      // Function dynamically created when X axis domain shift is in progress
      domainShift,
      // Boolean indicating X axis domain shif is in progress
      shiftingX = false,
      // Easing function used during X axis domain shift
      cubicEase = d3.ease('cubic'),
      // These are used to implement fluid X axis domain shifting.
      // This is used when plotting samples/points and extent of plotted
      // data approach extent of X axis.
      // Domain shifting can also occur when the current sample point is moved.
      // This most often occurs when using a graph to examine data from a model
      // and movingthe current sample point backwards and forwards in data that
      // have already been collected.

      // The style of the cursor when hovering over a sample.point marker.
      // The cursor changes depending on the operations that can be performed.
      markerCursorStyle,

      // Metrics calculated to support layout of titles, axes as
      // well as text and numeric labels for axes.
      fontSizeInPixels,
      halfFontSizeInPixels,
      quarterFontSizeInPixels,
      titleFontSizeInPixels,
      axisFontSizeInPixels,
      xlabelFontSizeInPixels,
      ylabelFontSizeInPixels,

      // Array objects containing width and height of X and Y axis labels
      xlabelMetrics,
      ylabelMetrics,

      // Width of widest numeric labels on X and Y axes
      xAxisNumberWidth,
      yAxisNumberWidth,

      // Height of numeric labels on X and Y axes
      xAxisNumberHeight,
      yAxisNumberHeight,

      // Padding necessary for X and Y axis labels to leave enough room for numeric labels
      xAxisVerticalPadding,
      yAxisHorizontalPadding,

      // Padding necessary between right side of interior plot and edge of graph so
      // make room for numeric lanel on right edge of X axis.
      xAxisLabelHorizontalPadding,

      // Baselines calculated for positioning of X and Y axis labels.
      xAxisLabelBaseline,
      yAxisLabelBaseline,

      // Thickness of draggable areas for rescaling axes, these surround numeric labels
      xAxisDraggableHeight,
      yAxisDraggableWidth,

      // D3 SVG rects used to implement axis dragging
      xAxisDraggable,
      yAxisDraggable,

      // Strings used as tooltips when numeric axis draggables are visible but responsive
      // layout system has removed the axis labels because of small size of graph.
      xAxisDraggableTooltip,
      yAxisDraggableTooltip,

      // Used to calculate styles for markers appearing on samples/points (normally circles)
      markerRadius,
      markerStrokeWidth,

      // Stroke width used for lines in graph
      lineWidth,

      // Used to categorize size of graphs in responsive layout mode where
      // certain graph chrome is removed when graph is rendered smaller.
      sizeType = {
        category: "medium",
        value: 3,
        icon: 120,
        tiny: 240,
        small: 480,
        medium: 960,
        large: 1920
      },

      // State variables indicating whether an axis drag operation is in place.
      // NaN values are used to indicate operation not in progress and
      // checked like this: if (!isNaN(downx)) { resacle operation in progress }
      //
      // When drag/rescale operation is occuring values contain plot
      // coordinates of start of drag (0 is a valid value).
      downx = NaN,
      downy = NaN,

      // State variable indicating whether a data point is being dragged.
      // When data point drag operation is occuring value contain two element
      // array wiith plot coordinates of drag position.
      draggedPoint = null,

      // When a data point is selected contains two element array wiith plot coordinates
      // of selected data point.
      selected = null,

      // An array of data points in the plot which are near the cursor.
      // Normally used to temporarily display data point markers when cursor
      // is nearby when markAllDataPoints is disabled.
      selectable = [],

      // An array containing two-element arrays consisting of X and Y values for samples/points
      points = [],

      // An array containing 1 or more points arrays to be plotted.
      pointArray,

      // When additional dataseries are added to the graph via addPoints(datapoints)
      // newDataSeries contains the number of series in dataPoints
      // Each series is a separate stream of data consisting of [x, y] pairs.
      // Additional static dataseries can be graphed along with the new series that
      // are streaming in as samples by pushing extra series into the array of data
      // setup with resetPoints().
      newDataSeries,

      // Index into points array for current sample/point.
      // Normally references data point last added.
      // Current sample can refer to earlier points. This is
      // represented in the view by using a desaturated styling for
      // plotted data after te currentSample.
      currentSample,

      // When graphing data samples as opposed to [x, y] data pairs contains
      // the fixed time interval between subsequent samples.
      sampleInterval,

      // Normally data sent to graph as samples starts at an X value of 0
      // A different starting x value can be set
      dataSampleStart,

      // The default options for a graph
      default_options = {
        // Enables the button layer with: AutoScale ...
        showButtons:    true,

        // Responsive Layout provides pregressive removal of
        // graph elements when size gets smaller
        responsiveLayout: false,

        // Font sizes for graphs are normally specified using ems.
        // When fontScaleRelativeToParent to true the font-size of the
        // containing element is set based on the size of the containing
        // element. hs means whn the containing element is smaller the
        // foint-size of the labels in thegraph will be smaller.
        fontScaleRelativeToParent: true,

        enableAutoScaleButton: true,
        enableAxisScaling: true,

        enableSelectionButton: false,
        clearSelectionOnLeavingSelectMode: false,

        //
        // dataType can be either 'points or 'samples'
        //
        dataType: 'points',
        //
        // dataType: 'points'
        //
        // Arrays of two-element arrays of x, y data pairs, this is the internal
        // format the graphers uses to represent data.
        dataPoints:      [],
        //
        // dataType: 'samples'
        //
        // An array of samples (or an array or arrays of samples)
        dataSamples:     [],
        // The constant time interval between sample values
        sampleInterval:  1,
        // Normally data sent to graph as samples starts at an X value of 0
        // A different starting x value can be set
        dataSampleStart: 0,

        // title can be a string or an array of strings, if an
        // array of strings each element is on a separate line.
        title:          "graph",

        // The labels for the axes, these are separate from the numeric labels.
        xlabel:         "x-axis",
        ylabel:         "y-axis",

        // Initial extent of the X and Y axes.
        xmax:            10,
        xmin:            0,
        ymax:            10,
        ymin:            0,

        // Approximate values for how many gridlines should appear on the axes.
        xTickCount:      10,
        yTickCount:      10,

        // The formatter strings used to convert numbers into strings.
        // see: https://github.com/mbostock/d3/wiki/Formatting#wiki-d3_format
        xFormatter:      ".3s",
        yFormatter:      ".3s",

        // Scale type: options are:
        //   linear: https://github.com/mbostock/d3/wiki/Quantitative-Scales#wiki-linear
        //   log:    https://github.com/mbostock/d3/wiki/Quantitative-Scales#wiki-log
        //   pow:    https://github.com/mbostock/d3/wiki/Quantitative-Scales#wiki-pow
        xscale:         'linear',
        yscale:         'linear',

        // Used when scale type is set to "pow"
        xscaleExponent:  0.5,
        yscaleExponent:  0.5,

        // How many samples/points over which a graph shift should take place
        // when the data being plotted gets close to the edge of the X axis.
        axisShift:       10,

        // selectablePoints: false,

        // true if data points should be marked ... currently marked with a circle.
        markAllDataPoints:   false,

        // only show circles when hovering near them with the mouse or
        // tapping near then on a tablet
        markNearbyDataPoints: false,

        // number of circles to show on each side of the central point
        extraCirclesVisibleOnHover: 2,

        // true to show dashed horizontal and vertical rulers when a circle is selected
        showRulersOnSelection: false,

        // width of the line used for plotting
        lineWidth:      2.0,

        // Enable values of data points to be changed by selecting and dragging.
        dataChange:      false,

        // Enables adding of data to a graph by option/alt clicking in the graph.
        addData:         false,

        // Set value to a string and it will be rendered in background of graph.
        notification:    false,

        // Render lines between samples/points
        lines:           true,

        // Render vertical bars extending up to samples/points
        bars:            false
      },

      // brush selection variables
      selection_region = {
        xmin: null,
        xmax: null,
        ymin: null,
        ymax: null
      },
      has_selection = false,
      selection_visible = false,
      selection_enabled = true,
      selection_listener,
      brush_element,
      brush_control;


  // ------------------------------------------------------------
  //
  // Initialization
  //
  // ------------------------------------------------------------

  function initialize(idOrElement, opts, mesg) {
    if (opts || !options) {
      options = setupOptions(opts);
    }

    initializeLayout(idOrElement, mesg);

    options.xrange = options.xmax - options.xmin;
    options.yrange = options.ymax - options.ymin;

    if (Object.prototype.toString.call(options.title) === "[object Array]") {
      titles = options.title;
    } else {
      titles = [options.title];
    }
    titles.reverse();

    // use local variables for both access speed and for responsive over-riding
    sampleInterval = options.sampleInterval;
    dataSampleStart = options.dataSampleStart;
    lineWidth = options.lineWidth;

    size = {
      "width":  120,
      "height": 120
    };

    setupScales();

    fx_d3 = d3.format(options.xFormatter);
    fy_d3 = d3.format(options.yFormatter);

    // Wrappers around certain d3 formatters to prevent problems like this:
    //   scale = d3.scale.linear().domain([-.7164, .7164])
    //   scale.ticks(10).map(d3.format('.3r'))
    //   => ["-0.600", "-0.400", "-0.200", "-0.0000000000000000888", "0.200", "0.400", "0.600"]

    fx = function(num) {
      var domain = xScale.domain(),
          onePercent = Math.abs((domain[1] - domain[0])*0.01);
      if (Math.abs(0+num) < onePercent) {
        num = 0;
      }
      return fx_d3(num);
    };

    fy = function(num) {
      var domain = yScale.domain(),
          onePercent = Math.abs((domain[1] - domain[0])*0.01);
      if (Math.abs(0+num) < onePercent) {
        num = 0;
      }
      return fy_d3(num);
    };

    xTickCount = options.xTickCount;
    yTickCount = options.yTickCount;

    pointArray = [];
    switch(options.dataType) {
      case "fake":
      points = fakeDataPoints();
      pointArray = [points];
      break;

      case 'points':
      resetDataPoints(options.dataPoints);
      break;

      case 'samples':
      resetDataSamples(options.dataSamples, sampleInterval, dataSampleStart);
      break;
    }

    selectable = [];
    selected = null;

    setCurrentSample(points.length);
  }

  function initializeLayout(idOrElement, mesg) {
    if (idOrElement) {
      // d3.select works both for element ID (e.g. "#grapher")
      // and for DOM element.
      elem = d3.select(idOrElement);
      node = elem.node();
      $node = $(node);
      // cx = $node.width();
      // cy = $node.height();
      cx = elem.property("clientWidth");
      cy = elem.property("clientHeight");
    }

    if (mesg) {
      message = mesg;
    }

    if (svg !== undefined) {
      svg.remove();
      svg = undefined;
    }

    if (background !== undefined) {
      background.remove();
      background = undefined;
    }

    if (graphCanvas !== undefined) {
      graphCanvas.remove();
      graphCanvas = undefined;
    }

    if (options.dataChange) {
      markerCursorStyle = "ns-resize";
    } else {
      markerCursorStyle = "crosshair";
    }

    scale();

    // drag axis logic
    downx = NaN;
    downy = NaN;
    draggedPoint = null;
  }

  function scale(w, h) {
    if (!w && !h) {
      cx = Math.max(elem.property("clientWidth"), 60);
      cy = Math.max(elem.property("clientHeight"),60);
    } else {
      cx = w;
      node.style.width =  cx +"px";
      if (!h) {
        node.style.height = "100%";
        h = elem.property("clientHeight");
        cy = h;
        node.style.height = cy +"px";
      } else {
        cy = h;
        node.style.height = cy +"px";
      }
    }
    calculateSizeType();
  }

  function calculateLayout(forceUpdate) {
    scale();

    fontSizeInPixels = parseFloat($node.css("font-size"));

    if (!options.fontScaleRelativeToParent) {
      $node.css("font-size", 0.5 + sizeType.value/6 + 'em');
    }

    fontSizeInPixels = parseFloat($node.css("font-size"));

    halfFontSizeInPixels = fontSizeInPixels/2;
    quarterFontSizeInPixels = fontSizeInPixels/4;

    if (svg === undefined) {
      titleFontSizeInPixels =  fontSizeInPixels;
      axisFontSizeInPixels =   fontSizeInPixels;
      xlabelFontSizeInPixels = fontSizeInPixels;
      ylabelFontSizeInPixels = fontSizeInPixels;
    } else {
      titleFontSizeInPixels =  parseFloat($("svg.graph text.title").css("font-size"));
      axisFontSizeInPixels =   parseFloat($("svg.graph text.axis").css("font-size"));
      xlabelFontSizeInPixels = parseFloat($("svg.graph text.xlabel").css("font-size"));
      ylabelFontSizeInPixels = parseFloat($("svg.graph text.ylabel").css("font-size"));
    }
    updateAxesAndSize();

    updateScales();

    line = d3.svg.line()
        .x(function(d, i) { return xScale(points[i][0]); })
        .y(function(d, i) { return yScale(points[i][1]); });
  }

  function setupOptions(options) {
    if (options) {
      for(var p in default_options) {
        if (options[p] === undefined) {
          options[p] = default_options[p];
        }
      }
    } else {
      options = default_options;
    }
    if (options.axisShift < 1) options.axisShift = 1;
    return options;
  }

  function updateAxesAndSize() {
    if (xScale === undefined) {
      xlabelMetrics = [fontSizeInPixels, fontSizeInPixels];
      ylabelMetrics = [fontSizeInPixels*2, fontSizeInPixels];
    } else {
      xlabelMetrics = axis.numberWidthUsingFormatter(elem, cx, cy, axisFontSizeInPixels,
        longestNumber(xScale.ticks(xTickCount), fx));

      ylabelMetrics = axis.numberWidthUsingFormatter(elem, cx, cy, axisFontSizeInPixels,
        longestNumber(yScale.ticks(yTickCount), fy));
    }

    xAxisNumberWidth  = xlabelMetrics[0];
    xAxisNumberHeight = xlabelMetrics[1];

    xAxisLabelHorizontalPadding = xAxisNumberWidth * 0.6;
    xAxisDraggableHeight = xAxisNumberHeight * 1.1;
    xAxisVerticalPadding = xAxisDraggableHeight + xAxisNumberHeight*1.3;
    xAxisLabelBaseline = xAxisVerticalPadding-xAxisNumberHeight/3;

    yAxisNumberWidth  = ylabelMetrics[0];
    yAxisNumberHeight = ylabelMetrics[1];

    yAxisDraggableWidth    = yAxisNumberWidth + xAxisNumberHeight/4;
    yAxisHorizontalPadding = yAxisDraggableWidth + yAxisNumberHeight;
    yAxisLabelBaseline     = -(yAxisDraggableWidth+yAxisNumberHeight/4);

    switch(sizeType.value) {
      case 0:         // icon
      padding = {
        "top":    halfFontSizeInPixels,
        "right":  halfFontSizeInPixels,
        "bottom": fontSizeInPixels,
        "left":   fontSizeInPixels
      };
      break;

      case 1:         // tiny
      padding = {
        "top":    options.title  ? titleFontSizeInPixels*1.8 : fontSizeInPixels,
        "right":  halfFontSizeInPixels,
        "bottom": fontSizeInPixels,
        "left":   fontSizeInPixels
      };
      break;

      case 2:         // small
      padding = {
        "top":    options.title  ? titleFontSizeInPixels*1.8 : fontSizeInPixels,
        "right":  xAxisLabelHorizontalPadding,
        "bottom": axisFontSizeInPixels*1.25,
        "left":   yAxisNumberWidth*1.25
      };
      xTickCount = Math.max(6, options.xTickCount/2);
      yTickCount = Math.max(6, options.yTickCount/2);
      break;

      case 3:         // medium
      padding = {
        "top":    options.title  ? titleFontSizeInPixels*1.8 : fontSizeInPixels,
        "right":  xAxisLabelHorizontalPadding,
        "bottom": options.xlabel ? xAxisVerticalPadding : axisFontSizeInPixels*1.25,
        "left":   options.ylabel ? yAxisHorizontalPadding : yAxisNumberWidth
      };
      break;

      default:         // large
      padding = {
        "top":    options.title  ? titleFontSizeInPixels*1.8 : fontSizeInPixels,
        "right":  xAxisLabelHorizontalPadding,
        "bottom": options.xlabel ? xAxisVerticalPadding : axisFontSizeInPixels*1.25,
        "left":   options.ylabel ? yAxisHorizontalPadding : yAxisNumberWidth
      };
      break;
    }

    if (sizeType.value > 2 ) {
      padding.top += (titles.length-1) * sizeType.value/3 * sizeType.value/3 * fontSizeInPixels;
    } else {
      titles = [titles[0]];
    }

    size.width  = Math.max(cx - padding.left - padding.right, 60);
    size.height = Math.max(cy - padding.top  - padding.bottom, 60);
  }

  function calculateSizeType() {
    if (options.responsiveLayout) {
      if (cx <= sizeType.icon) {
        sizeType.category = 'icon';
        sizeType.value = 0;
      } else if (cx <= sizeType.tiny) {
        sizeType.category = 'tiny';
        sizeType.value = 1;
      } else if (cx <= sizeType.small) {
        sizeType.category = 'small';
        sizeType.value = 2;
      } else if (cx <= sizeType.medium) {
        sizeType.category = 'medium';
        sizeType.value = 3;
      } else {
        sizeType.category = 'large';
        sizeType.value = 4;
      }
    } else {
      sizeType.category = 'large';
      sizeType.value = 4;
    }
  }

  function longestNumber(array, formatter, precision) {
    var longest = 0,
        index = 0,
        str,
        len,
        i;
    precision = precision || 5;
    for (i = 0; i < array.length; i++) {
      str = formatter(+array[i].toPrecision(precision));
      str = str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
      len = str.length;
      if (len > longest) {
        longest = len;
        index = i;
      }
    }
    return formatter(array[index]);
  }

  // Setup xScale, yScale, making sure that options.xmax/xmin/ymax/ymin always reflect changes to
  // the relevant domains.
  function setupScales() {
    function domainObservingScale(scale, callback) {
      var domain = scale.domain;
      scale.domain = function(_) {
        if (arguments.length) {
          callback(_);
        }
        return domain.apply(scale, arguments);
      };
      return scale;
    }

    xScale = domainObservingScale(d3.scale[options.xscale](), function(_) {
      options.xmin = _[0];
      options.xmax = _[1];
    });
    yScale = domainObservingScale(d3.scale[options.yscale](), function(_) {
      options.ymin = _[0];
      options.ymax = _[1];
    });
    updateScales();
  }

  function updateScales() {
    updateXScale();
    updateYScale();
  }

  // Update the x-scale.
  function updateXScale() {
    xScale.domain([options.xmin, options.xmax])
          .range([0, size.width]);
    cancelDomainShift();
  }

  // Update the y-scale.
  function updateYScale() {
    yScale.domain([options.ymin, options.ymax])
          .range([size.height, 0]);
  }

  function fakeDataPoints() {
    var yrange2 = options.yrange / 2,
        yrange4 = yrange2 / 2,
        pnts;

    options.datacount = size.width/30;
    options.xtic = options.xrange / options.datacount;
    options.ytic = options.yrange / options.datacount;

    pnts = d3.range(options.datacount).map(function(i) {
      return [i * options.xtic + options.xmin, options.ymin + yrange4 + Math.random() * yrange2 ];
    });
    return pnts;
  }

  function setCurrentSample(samplePoint) {
    if (typeof samplePoint === "number") {
      currentSample = samplePoint;
    }
    if (typeof currentSample !== "number") {
      currentSample = points.length-1;
    }
    return currentSample;
  }

  // converts data samples into an array of points
  function indexedData(samples, interval, start) {
    var i = 0,
        pnts = [];
    interval = interval || 1;
    start = start || 0;
    for (i = 0; i < samples.length;  i++) {
      pnts.push([i * interval + start, samples[i]]);
    }
    return pnts;
  }

  //
  // Update notification message
  //
  function notify(mesg) {
    message = mesg;
    if (mesg) {
      notification.text(mesg);
    } else {
      notification.text('');
    }
  }


  function createButtonLayer() {
    buttonLayer = elem.append("div");

    buttonLayer
      .attr("class", "button-layer")
      .style("z-index", 3);

    if (options.enableAutoScaleButton) {
      buttonLayer.append('a')
          .attr({
            "class": "autoscale-button",
            "title": tooltips.autoscale
          })
          .on("click", function() {
            autoscale();
          })
          .append("i")
            .attr("class", "icon-picture");
    }

    if (options.enableSelectionButton) {
      selectionButton = buttonLayer.append('a');
      selectionButton.attr({
            "class": "selection-button",
            "title": tooltips.selection
          })
          .on("click", function() {
            toggleSelection();
          })
          .append("i")
            .attr("class", "icon-cut");
    }

    resizeButtonLayer();
  }

  function resizeButtonLayer() {
    buttonLayer
      .style({
        "width":   fontSizeInPixels*1.75 + "px",
        "height":  fontSizeInPixels*1.25 + "px",
        "top":     padding.top + halfFontSizeInPixels + "px",
        "left":    padding.left + (size.width - fontSizeInPixels*2.0) + "px"
      });
  }

  // ------------------------------------------------------------
  //
  // Rendering
  //
  // ------------------------------------------------------------

  //
  // Render a new graph by creating the SVG and Canvas elements
  //
  function renderNewGraph() {
    svg = elem.append("svg")
        .attr("width",  cx)
        .attr("height", cy)
        .attr("class", "graph")
        .style('z-index', 2);
        // .attr("tabindex", tabindex || 0);

    vis = svg.append("g")
        .attr("transform", "translate(" + padding.left + "," + padding.top + ")");

    plot = vis.append("rect")
      .attr("class", "plot")
      .attr("width", size.width)
      .attr("height", size.height)
      .attr("pointer-events", "all")
      .attr("fill", "rgba(255,255,255,0)")
      .on("mousemove", plotMousemove)
      .on("mousedown", plotDrag)
      .on("touchstart", plotDrag);

    plot.call(d3.behavior.zoom().x(xScale).y(yScale).on("zoom", redraw));

    background = elem.append("div")
        .attr("class", "background")
        .style({
          "width":   size.width + "px",
          "height":  size.height + "px",
          "top":     padding.top + "px",
          "left":    padding.left + "px",
          "z-index": 0
        });

    createGraphCanvas();

    viewbox = vis.append("svg")
      .attr("class", "viewbox")
      .attr("top", 0)
      .attr("left", 0)
      .attr("width", size.width)
      .attr("height", size.height)
      .attr("viewBox", "0 0 "+size.width+" "+size.height);

    selectedRulerX = viewbox.append("line")
      .attr("stroke", gridStroke)
      .attr("stroke-dasharray", "2,2")
      .attr("y1", 0)
      .attr("y2", size.height)
      .attr("x1", function(d) { return selected === null ? 0 : selected[0]; } )
      .attr("x2", function(d) { return selected === null ? 0 : selected[0]; } )
      .attr("class", "ruler hidden");

    selectedRulerY = viewbox.append("line")
      .attr("stroke", gridStroke)
      .attr("stroke-dasharray", "2,2")
      .attr("x1", 0)
      .attr("x2", size.width)
      .attr("y1", function(d) { return selected === null ? 0 : selected[1]; } )
      .attr("y2", function(d) { return selected === null ? 0 : selected[1]; } )
      .attr("class", "ruler hidden");

    yAxisDraggable = svg.append("rect")
      .attr("class", "draggable-axis")
      .attr("x", padding.left-yAxisDraggableWidth)
      .attr("y", padding.top)
      .attr("rx", yAxisNumberHeight/6)
      .attr("width", yAxisDraggableWidth)
      .attr("height", size.height)
      .attr("pointer-events", "all")
      .style("cursor", "row-resize")
      .on("mousedown", yAxisDrag)
      .on("touchstart", yAxisDrag);

    yAxisDraggableTooltip = yAxisDraggable.append("title");

    xAxisDraggable = svg.append("rect")
      .attr("class", "draggable-axis")
      .attr("x", padding.left)
      .attr("y", size.height+padding.top)
      .attr("rx", yAxisNumberHeight/6)
      .attr("width", size.width)
      .attr("height", xAxisDraggableHeight)
      .attr("pointer-events", "all")
      .style("cursor", "col-resize")
      .on("mousedown", xAxisDrag)
      .on("touchstart", xAxisDrag);

    xAxisDraggableTooltip = xAxisDraggable.append("title");

    if (sizeType.value <= 2 && options.ylabel) {
      xAxisDraggableTooltip.text(options.xlabel);
    }

    if (sizeType.catefory && options.ylabel) {
      yAxisDraggableTooltip.text(options.ylabel);
    }

    adjustAxisDraggableFill();

    brush_element = viewbox.append("g")
          .attr("class", "brush");

    // add Chart Title
    if (options.title && sizeType.value > 0) {
      title = vis.selectAll("text")
        .data(titles, function(d) { return d; });
      title.enter().append("text")
          .attr("class", "title")
          .text(function(d) { return d; })
          .attr("x", function(d) { return size.width/2 - Math.min(size.width, getComputedTextLength(this))/2; })
          .attr("dy", function(d, i) { return -i * titleFontSizeInPixels - halfFontSizeInPixels + "px"; });
      titleTooltip = title.append("title")
          .text("");
    } else if (options.title) {
      titleTooltip = plot.append("title")
          .text(options.title);
    }

    // Add the x-axis label
    if (sizeType.value > 2) {
      xlabel = vis.append("text")
          .attr("class", "axis")
          .attr("class", "xlabel")
          .text(options.xlabel)
          .attr("x", size.width/2)
          .attr("y", size.height)
          .attr("dy", xAxisLabelBaseline + "px")
          .style("text-anchor","middle");
    }

    // add y-axis label
    if (sizeType.value > 2) {
      ylabel = vis.append("g").append("text")
          .attr("class", "axis")
          .attr("class", "ylabel")
          .text( options.ylabel)
          .style("text-anchor","middle")
          .attr("transform","translate(" + yAxisLabelBaseline + " " + size.height/2+") rotate(-90)");
      if (sizeType.category === "small") {
        yAxisDraggable.append("title")
          .text(options.ylabel);
      }
    }

    d3.select(node)
        .on("mousemove.drag", mousemove)
        .on("touchmove.drag", mousemove)
        .on("mouseup.drag",   mouseup)
        .on("touchend.drag",  mouseup);

    notification = vis.append("text")
        .attr("class", "graph-notification")
        .text(message)
        .attr("x", size.width/2)
        .attr("y", size.height/2)
        .style("text-anchor","middle");

    updateMarkers();
    updateRulers();
  }

  //
  // Repaint an existing graph by rescaling/updating the SVG and Canvas elements
  //
  function repaintExistingGraph() {
    vis
      .attr("width",  cx)
      .attr("height", cy)
      .attr("transform", "translate(" + padding.left + "," + padding.top + ")");

    plot
      .attr("width", size.width)
      .attr("height", size.height);

    background
      .style({
        "width":   size.width + "px",
        "height":  size.height + "px",
        "top":     padding.top + "px",
        "left":    padding.left + "px",
        "z-index": 0
      });

    viewbox
        .attr("top", 0)
        .attr("left", 0)
        .attr("width", size.width)
        .attr("height", size.height)
        .attr("viewBox", "0 0 "+size.width+" "+size.height);

    yAxisDraggable
        .attr("x", padding.left-yAxisDraggableWidth)
        .attr("y", padding.top-yAxisNumberHeight/2)
        .attr("width", yAxisDraggableWidth)
        .attr("height", size.height+yAxisNumberHeight);

    xAxisDraggable
        .attr("x", padding.left)
        .attr("y", size.height+padding.top)
        .attr("width", size.width)
        .attr("height", xAxisDraggableHeight);

    adjustAxisDraggableFill();

    if (options.title && sizeType.value > 0) {
      title
          .attr("x", function(d) { return size.width/2 - Math.min(size.width, getComputedTextLength(this))/2; })
          .attr("dy", function(d, i) { return -i * titleFontSizeInPixels - halfFontSizeInPixels + "px"; });
      titleTooltip
          .text("");
    } else if (options.title) {
      titleTooltip
          .text(options.title);
    }

    if (options.xlabel && sizeType.value > 2) {
      xlabel
          .attr("x", size.width/2)
          .attr("y", size.height)
          .attr("dy", xAxisLabelBaseline + "px");
      xAxisDraggableTooltip
          .text("");
    } else {
      xAxisDraggableTooltip
          .text(options.xlabel);
    }

    if (options.ylabel && sizeType.value > 2) {
      ylabel
          .attr("transform","translate(" + yAxisLabelBaseline + " " + size.height/2+") rotate(-90)");
      yAxisDraggableTooltip
          .text("");
    } else {
      yAxisDraggableTooltip
        .text(options.ylabel);
    }

    notification
      .attr("x", size.width/2)
      .attr("y", size.height/2);

    vis.selectAll("g.x").remove();
    vis.selectAll("g.y").remove();

    if (has_selection && selection_visible) {
      updateBrushElement();
    }

    updateMarkers();
    updateRulers();
    resizeCanvas();
  }

  function getComputedTextLength(el) {
    if (el.getComputedTextLength) {
      return el.getComputedTextLength();
    } else {
      return 100;
    }
  }

  function adjustAxisDraggableFill() {
    if (sizeType.value <= 1) {
      xAxisDraggable
        .style({
          "fill":       "rgba(196, 196, 196, 0.2)"
        });
      yAxisDraggable
        .style({
          "fill":       "rgba(196, 196, 196, 0.2)"
        });
    } else {
      xAxisDraggable
        .style({
          "fill":       null
        });
      yAxisDraggable
        .style({
          "fill":       null
        });
    }
  }

  //
  // Redraw the plot and axes when plot is translated or axes are re-scaled
  //
  function redraw() {
    updateAxesAndSize();
    repaintExistingGraph();
    // Regenerate x-ticks
    var gx = vis.selectAll("g.x")
        .data(xScale.ticks(xTickCount), String)
        .attr("transform", tx);

    var gxe = gx.enter().insert("g", "a")
        .attr("class", "x")
        .attr("transform", tx);

    gxe.append("line")
        .attr("stroke", gridStroke)
        .attr("y1", 0)
        .attr("y2", size.height);

    if (sizeType.value > 1) {
      gxe.append("text")
          .attr("class", "axis")
          .attr("y", size.height)
          .attr("dy", axisFontSizeInPixels + "px")
          .attr("text-anchor", "middle")
          .text(fx)
          .on("mouseover", function() { d3.select(this).style("font-weight", "bold");})
          .on("mouseout",  function() { d3.select(this).style("font-weight", "normal");});
    }

    gx.exit().remove();

    // Regenerate y-ticks
    var gy = vis.selectAll("g.y")
        .data(yScale.ticks(yTickCount), String)
        .attr("transform", ty);

    var gye = gy.enter().insert("g", "a")
        .attr("class", "y")
        .attr("transform", ty)
        .attr("background-fill", "#FFEEB6");

    gye.append("line")
        .attr("stroke", gridStroke)
        .attr("x1", 0)
        .attr("x2", size.width);

    if (sizeType.value > 1) {
      if (options.yscale === "log") {
        var gye_length = gye[0].length;
        if (gye_length > 100) {
          gye = gye.filter(function(d) { return !!d.toString().match(/(\.[0]*|^)[1]/);});
        } else if (gye_length > 50) {
          gye = gye.filter(function(d) { return !!d.toString().match(/(\.[0]*|^)[12]/);});
        } else {
          gye = gye.filter(function(d) {
            return !!d.toString().match(/(\.[0]*|^)[125]/);});
        }
      }
      gye.append("text")
          .attr("class", "axis")
          .attr("x", -axisFontSizeInPixels/4 + "px")
          .attr("dy", ".35em")
          .attr("text-anchor", "end")
          .style("cursor", "ns-resize")
          .text(fy)
          .on("mouseover", function() { d3.select(this).style("font-weight", "bold");})
          .on("mouseout",  function() { d3.select(this).style("font-weight", "normal");});
    }

    gy.exit().remove();
    plot.call(d3.behavior.zoom().x(xScale).y(yScale).on("zoom", redraw));
    update();
  }

  // ------------------------------------------------------------
  //
  // Rendering: Updating samples/data points in the plot
  //
  // ------------------------------------------------------------


  //
  // Update plotted data, optionally pass in new samplePoint
  //
  function update(samplePoint) {
    setCurrentSample(samplePoint);
    updateCanvasFromPoints(currentSample);
    updateMarkers();
    if (d3.event && d3.event.keyCode) {
      d3.event.preventDefault();
      d3.event.stopPropagation();
    }
  }

  // samplePoint is optional argument
  function updateOrRescale(samplePoint) {
    setCurrentSample(samplePoint);
    updateOrRescalePoints();
  }

  // samplePoint is optional argument
  function updateOrRescalePoints(samplePoint) {
    var domain = xScale.domain(),
        xAxisStart = Math.round(domain[0]),
        xAxisEnd = Math.round(domain[1]),
        start = Math.max(0, xAxisStart),
        xextent = domain[1] - domain[0],
        shiftPoint = xextent * 0.95,
        currentExtent;

    setCurrentSample(samplePoint);
    if (currentSample > 0) {
      currentExtent = points[currentSample-1][0];
    } else {
      currentExtent = points[currentSample][0];
    }
    if (shiftingX) {
      shiftingX = domainShift();
      if (shiftingX) {
        cancelAxisRescale();
        redraw();
      } else {
        update(currentSample);
      }
    } else {
      if (currentExtent > domain[0] + shiftPoint) {
        domainShift = shiftXDomainRealTime(shiftPoint*0.9, options.axisShift);
        shiftingX = domainShift();
        redraw();
      } else if ( currentExtent < domain[1] - shiftPoint && currentSample < points.length && xAxisStart > 0) {
        domainShift = shiftXDomainRealTime(shiftPoint*0.9, options.axisShift, -1);
        shiftingX = domainShift();
        redraw();
      } else if (currentExtent < domain[0]) {
        domainShift = shiftXDomainRealTime(shiftPoint*0.1, 1, -1);
        shiftingX = domainShift();
        redraw();
      } else {
        update(currentSample);
      }
    }
  }

  function shiftXDomainRealTime(shift, steps, direction) {
    var d0 = xScale.domain()[0],
        d1 = xScale.domain()[1],
        increment = 1/steps,
        index = 0;
    return function() {
      var factor;
      direction = direction || 1;
      index += increment;
      factor = shift * cubicEase(index);
      if (direction > 0) {
        xScale.domain([d0 + factor, d1 + factor]);
        return xScale.domain()[0] < (d0 + shift);
      } else {
        xScale.domain([d0 - factor, d1 - factor]);
        return xScale.domain()[0] > (d0 - shift);
      }
    };
  }

  function cancelDomainShift() {
    shiftingX = false;
    // effectively asserts that we don't call domainShift until a new domain shift is required
    domainShift = null;
  }

  function cancelAxisRescale() {
    if (!isNaN(downx)) {
      downx = NaN;
    }
    if (!isNaN(downy)) {
      downy = NaN;
    }
  }

  function circleClasses(d) {
    var cs = [];
    if (d === selected) {
      cs.push("selected");
    }
    if (cs.length === 0) {
      return null;
    } else {
      return cs.join(" ");
    }
  }

  function updateMarkerRadius() {
    var d = xScale.domain(),
        r = xScale.range();
    markerRadius = (r[1] - r[0]) / ((d[1] - d[0]));
    markerRadius = Math.min(Math.max(markerRadius, 4), 8);
    markerStrokeWidth = markerRadius/3;
  }

  function updateMarkers() {
    var marker,
        markedPoints = null;
    if (options.markAllDataPoints && sizeType.value > 1) {
      markedPoints = points;
    } else if (options.markNearbyDataPoints && sizeType.value > 1) {
      markedPoints = selectable.slice(0);
      if (selected !== null && markedPoints.indexOf(selected) === -1) {
        markedPoints.push(selected);
      }
    }
    if (markedPoints !== null) {
      updateMarkerRadius();
      marker = vis.select("svg").selectAll("circle").data(markedPoints);
      marker.enter().append("circle")
          .attr("class", circleClasses)
          .attr("cx",    function(d) { return xScale(d[0]); })
          .attr("cy",    function(d) { return yScale(d[1]); })
          .attr("r", markerRadius)
          .style("stroke-width", markerStrokeWidth)
          .style("cursor", markerCursorStyle)
          .on("mousedown.drag",  dataPointDrag)
          .on("touchstart.drag", dataPointDrag)
          .append("title")
          .text(function(d) { return "( " + fx(d[0]) + ", " + fy(d[1]) + " )"; });

      marker
          .attr("class", circleClasses)
          .attr("cx",    function(d) { return xScale(d[0]); })
          .attr("cy",    function(d) { return yScale(d[1]); })
          .select("title")
          .text(function(d) { return "( " + fx(d[0]) + ", " + fy(d[1]) + " )"; });

      marker.exit().remove();
    }

    updateRulers();
  }

  function updateRulers() {
    if (options.showRulersOnSelection && selected !== null) {
      selectedRulerX
        .attr("y1", 0)
        .attr("y2", size.height)
        .attr("x1", function(d) { return selected === null ? 0 : xScale(selected[0]); } )
        .attr("x2", function(d) { return selected === null ? 0 : xScale(selected[0]); } )
        .attr("class", function(d) { return "ruler" + (selected === null ? " hidden" : ""); } );

      selectedRulerY
        .attr("x1", 0)
        .attr("x2", size.width)
        .attr("y1", function(d) { return selected === null ? 0 : yScale(selected[1]); } )
        .attr("y2", function(d) { return selected === null ? 0 : yScale(selected[1]); } )
        .attr("class", function(d) { return "ruler" + (selected === null ? " hidden" : ""); } );
    } else {
      selectedRulerX.attr("class", "ruler hidden");
      selectedRulerY.attr("class", "ruler hidden");
    }
  }


  // ------------------------------------------------------------
  //
  // UI Interaction: Plot dragging and translation; Axis re-scaling
  //
  // ------------------------------------------------------------

  function plotMousemove() {
    if (options.markNearbyDataPoints) {
      var mousePoint = d3.mouse(vis.node()),
          translatedMousePointX = xScale.invert(Math.max(0, Math.min(size.width, mousePoint[0]))),
          p,
          idx, pMin, pMax,
          i;
      // highlight the central point, and also points to the left and right
      // TODO Handle multiple data sets/lines
      selectable = [];
      for (i = 0; i < pointArray.length; i++) {
        points = pointArray[i];
        p = findClosestPointByX(translatedMousePointX, i);
        if (p !== null) {
          idx = points.indexOf(p);
          pMin = idx - (options.extraCirclesVisibleOnHover);
          pMax = idx + (options.extraCirclesVisibleOnHover + 1);
          if (pMin < 0) { pMin = 0; }
          if (pMax > points.length - 1) { pMax = points.length; }
          selectable = selectable.concat(points.slice(pMin, pMax));
        }
      }
      update();
    }
  }

  function findClosestPointByX(x, line) {
    if (typeof(line) === "undefined" || line === null) { line = 0; }
    // binary search through points.
    // This assumes points is sorted ascending by x value, which for realTime graphs is true.
    points = pointArray[line];
    if (points.length === 0) { return null; }
    var min = 0,
        max = points.length - 1,
        mid, diff, p1, p2, p3;
    while (min < max) {
      mid = Math.floor((min + max)/2.0);
      if (points[mid][0] < x) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }

    // figure out which point is actually closest.
    // we have to compare 3 points, to account for floating point rounding errors.
    // if the mouse moves off the left edge of the graph, p1 may not exist.
    // if the mouse moves off the right edge of the graph, p3 may not exist.
    p1 = points[mid - 1];
    p2 = points[mid];
    p3 = points[mid + 1];
    if (typeof(p1) !== "undefined" && Math.abs(p1[0] - x) <= Math.abs(p2[0] - x)) {
      return p1;
    } else if (typeof(p3) === "undefined" || Math.abs(p2[0] - x) <= Math.abs(p3[0] - x)) {
      return p2;
    } else {
      return p3;
    }
  }

  function plotDrag() {
    if(options.enableAxisScaling) {
      var p;
      d3.event.preventDefault();
      d3.select('body').style("cursor", "move");
      if (d3.event.altKey) {
        plot.style("cursor", "nesw-resize");
        if (d3.event.shiftKey && options.addData) {
          p = d3.mouse(vis.node());
          var newpoint = [];
          newpoint[0] = xScale.invert(Math.max(0, Math.min(size.width,  p[0])));
          newpoint[1] = yScale.invert(Math.max(0, Math.min(size.height, p[1])));
          points.push(newpoint);
          points.sort(function(a, b) {
            if (a[0] < b[0]) { return -1; }
            if (a[0] > b[0]) { return  1; }
            return 0;
          });
          selected = newpoint;
          update();
        } else {
          p = d3.mouse(vis.node());
          downx = xScale.invert(p[0]);
          downy = yScale.invert(p[1]);
          draggedPoint = false;
          d3.event.stopPropagation();
        }
        // d3.event.stopPropagation();
      }
    }
  }

  function falseFunction() {
    return false;
  }

  function xAxisDrag() {
    if(options.enableAxisScaling) {
      node.focus();
      document.onselectstart = falseFunction;
      d3.event.preventDefault();
      var p = d3.mouse(vis.node());
      downx = xScale.invert(p[0]);
    }
  }

  function yAxisDrag() {
    if(options.enableAxisScaling) {
      node.focus();
      d3.event.preventDefault();
      document.onselectstart = falseFunction;
      var p = d3.mouse(vis.node());
      downy = yScale.invert(p[1]);
    }
  }

  function dataPointDrag(d) {
    node.focus();
    d3.event.preventDefault();
    document.onselectstart = falseFunction;
    if (selected === d) {
      selected = draggedPoint = null;
    } else {
      selected = draggedPoint = d;
    }
    update();
  }

  function mousemove() {
    var p = d3.mouse(vis.node()),
        index,
        px,
        x,
        nextPoint,
        prevPoint,
        minusHalf,
        plusHalf;

    // t = d3.event.changedTouches;

    document.onselectstart = function() { return true; };
    d3.event.preventDefault();
    if (draggedPoint) {
      if (options.dataChange) {
        draggedPoint[1] = yScale.invert(Math.max(0, Math.min(size.height, p[1])));
      } else {
        index = points.indexOf(draggedPoint);
        if (index && index < (points.length-1)) {
          px = xScale.invert(p[0]);
          x = draggedPoint[0];
          nextPoint = points[index+1];
          prevPoint = points[index-1];
          minusHalf = x - (x - prevPoint[0])/2;
          plusHalf =  x + (nextPoint[0] - x)/2;
          if (px < minusHalf) {
            draggedPoint = prevPoint;
            selected = draggedPoint;
          } else if (px > plusHalf) {
            draggedPoint = nextPoint;
            selected = draggedPoint;
          }
        }
      }
      update();
    }

    if (!isNaN(downx)) {
      d3.select('body').style("cursor", "col-resize");
      plot.style("cursor", "col-resize");
      if (shiftingX) {
        xScale.domain(axis.axisProcessDrag(downx, xScale.invert(p[0]), xScale.domain()));
      } else {
        xScale.domain(axis.axisProcessDrag(downx, xScale.invert(p[0]), xScale.domain()));
      }
      updateMarkerRadius();
      redraw();
      d3.event.stopPropagation();
    }

    if (!isNaN(downy)) {
      d3.select('body').style("cursor", "row-resize");
      plot.style("cursor", "row-resize");
      yScale.domain(axis.axisProcessDrag(downy, yScale.invert(p[1]), yScale.domain()));
      redraw();
      d3.event.stopPropagation();
    }
  }

  function mouseup() {
    d3.select('body').style("cursor", "auto");
    plot.style("cursor", "auto");
    document.onselectstart = function() { return true; };
    if (!isNaN(downx)) {
      redraw();
      downx = NaN;
    }
    if (!isNaN(downy)) {
      redraw();
      downy = NaN;
    }
    draggedPoint = null;
  }

  //------------------------------------------------------
  //
  // Autoscale
  //
  // ------------------------------------------------------------

  /**
    If there are more than 1 data points, scale the x axis to contain all x values,
    and scale the y axis so that the y values lie in the middle 80% of the visible y range.

    Then nice() the x and y scales (which means that the x and y domains will likely expand
    somewhat).
  */
  function autoscale() {
    var i,
        j,
        len,
        point,
        x,
        y,
        xmin = Infinity,
        xmax = -Infinity,
        ymin = Infinity,
        ymax = -Infinity,
        transform,
        pow;

    if (points.length < 2) return;

    for (i = 0; i < pointArray.length; i++) {
      points = pointArray[i];
      for (j = 0, len = points.length; j < len; j++){
        point = points[j];
        x = point[0];
        y = point[1];

        if (x < xmin) xmin = x;
        if (x > xmax) xmax = x;
        if (y < ymin) ymin = y;
        if (y > ymax) ymax = y;
      }
    }

    // Like Math.pow but returns a value with the same sign as x: pow(-1, 0.5) -> -1
    pow = function(x, exponent) {
      return x < 0 ? -Math.pow(-x, exponent) : Math.pow(x, exponent);
    };

    // convert ymin, ymax to a linear scale, and set 'transform' to the function that
    // converts the new min, max to the relevant scale.
    switch (options.yscale) {
      case 'linear':
        transform = function(x) { return x; };
        break;
      case 'log':
        ymin = Math.log(ymin) / Math.log(10);
        ymax = Math.log(ymax) / Math.log(10);
        transform = function(x) { return Math.pow(10, x); };
        break;
      case 'pow':
        ymin = pow(ymin, options.yscaleExponent);
        ymax = pow(ymax, options.yscaleExponent);
        transform = function(x) { return pow(x, 1/options.yscaleExponent); };
        break;
    }

    xScale.domain([xmin, xmax]).nice();
    yScale.domain([transform(ymin - 0.15*(ymax-ymin)), transform(ymax + 0.15*(ymax-ymin))]).nice();
    redraw();
  }

  // ------------------------------------------------------------
  //
  // Brush Selection
  //
  // ------------------------------------------------------------

  function toggleSelection() {
    if (!selectionVisible()) {
      // The graph model defaults to visible=false and enabled=true.
      // Reset these so that this first click turns on selection correctly.
      selectionEnabled(false);
      selectionVisible(true);
    }
    if (!!selectionEnabled()) {
      if (options.clearSelectionOnLeavingSelectMode || selectionDomain() === []) {
        selectionDomain(null);
      }
      selectionEnabled(false);
    } else {
      if (selectionDomain() == null) {
        selectionDomain([]);
      }
      selectionEnabled(true);
    }
  }

  /**
    Set or get the selection domain (i.e., the range of x values that are selected).

    Valid domain specifiers:
      null     no current selection (selection is turned off)
      []       a current selection exists but is empty (has_selection is true)
      [x1, x2] the region between x1 and x2 is selected. Any data points between
               x1 and x2 (inclusive) would be considered to be selected.

    Default value is null.
  */
  function selectionDomain(a) {

    if (!arguments.length) {
      if (!has_selection) {
        return null;
      }
      if (selection_region.xmax === Infinity && selection_region.xmin === Infinity ) {
        return [];
      }
      return [selection_region.xmin, selection_region.xmax];
    }

    // setter

    if (a === null) {
      has_selection = false;
    }
    else if (a.length === 0) {
      has_selection = true;
      selection_region.xmin = Infinity;
      selection_region.xmax = Infinity;
    }
    else {
      has_selection = true;
      selection_region.xmin = a[0];
      selection_region.xmax = a[1];
    }

    updateBrushElement();

    if (selection_listener) {
      selection_listener(selectionDomain());
    }
    return api;
  }

  /**
    Get whether the graph currently has a selection region. Default value is false.

    If true, it would be valid to filter the data points to return a subset within the selection
    region, although this region may be empty!

    If false the graph is not considered to have a selection region.

    Note that even if has_selection is true, the selection region may not be currently shown,
    and if shown, it may be empty.
  */
  function hasSelection() {
    return has_selection;
  }

  /**
    Set or get the visibility of the selection region. Default value is false.

    Has no effect if the graph does not currently have a selection region
    (selection_domain is null).

    If the selection_enabled property is true, the user will also be able to interact
    with the selection region.
  */
  function selectionVisible(val) {
    if (!arguments.length) {
      return selection_visible;
    }

    // setter
    val = !!val;
    if (selection_visible !== val) {
      selection_visible = val;
      updateBrushElement();
    }
    return api;
  }

  /**
    Set or get whether user manipulation of the selection region should be enabled
    when a selection region exists and is visible. Default value is true.

    Setting the value to true has no effect unless the graph has a selection region
    (selection_domain is non-null) and the region is visible (selection_visible is true).
    However, the selection_enabled setting is honored whenever those properties are
    subsequently updated.

    Setting the value to false does not affect the visibility of the selection region,
    and does not affect the ability to change the region by calling selectionDomain().

    Note that graph panning and zooming are disabled while selection manipulation is enabled.
  */
  function selectionEnabled(val) {
    if (!arguments.length) {
      return selection_enabled;
    }

    // setter
    val = !!val;
    if (selection_enabled !== val) {
      selection_enabled = val;

      if (selectionButton) {
        if (val) {
          selectionButton.attr("style", "color: #aa0000;");
        } else {
          selectionButton.attr("style", "");
        }
      }

      updateBrushElement();
    }
    return api;
  }

  /**
    Set or get the listener to be called when the selection_domain changes.

    Both programatic and interactive updates of the selection region result in
    notification of the listener.

    The listener is called with the new selection_domain value in the first argument.
  */
  function selectionListener(cb) {
    if (!arguments.length) {
      return selection_listener;
    }
    // setter
    selection_listener = cb;
    return api;
  }

  function brushListener() {
    var extent;
    if (selection_enabled) {
      // Note there is a brush.empty() method, but it still reports true after the
      // brush extent has been programatically updated.
      extent = brush_control.extent();
      selectionDomain( extent[0] !== extent[1] ? extent : [] );
    }
  }

  function updateBrushElement() {
    if (has_selection && selection_visible) {
      brush_control = brush_control || d3.svg.brush()
        .x(xScale)
        .extent([selection_region.xmin || 0, selection_region.xmax || 0])
        .on("brush", brushListener);

      brush_element
        .call(brush_control.extent([selection_region.xmin || 0, selection_region.xmax || 0]))
        .style('display', 'inline')
        .style('pointer-events', selection_enabled ? 'all' : 'none')
        .selectAll("rect")
          .attr("height", size.height);

    } else {
      brush_element.style('display', 'none');
    }
  }

  // ------------------------------------------------------------
  //
  // Canvas-based plotting
  //
  // ------------------------------------------------------------

  function createGraphCanvas() {
    graphCanvas = elem.append("canvas");
    gcanvas = graphCanvas.node();
    resizeCanvas();
  }

  function resizeCanvas() {
    graphCanvas
      .attr("class", "overlay")
      .style({
        "position": "absolute",
        "width":    size.width + "px",
        "height":   size.height + "px",
        "top":      padding.top + "px",
        "left":     padding.left + "px",
        "z-index": 1
      });
    gcanvas = graphCanvas.node();
    gcanvas.width = size.width;
    gcanvas.height = size.height;
    gcanvas.top = padding.top;
    gcanvas.left = padding.left;
    setupCanvasContext();
    updateCanvasFromPoints(currentSample);
  }

  function clearCanvas() {
    if (gcanvas.getContext) {
      gcanvas.width = gcanvas.width;
      gctx.lineWidth = lineWidth;
      gctx.fillStyle = canvasFillStyle;
      gctx.fillRect(0, 0, gcanvas.width, gcanvas.height);
      gctx.strokeStyle = "rgba(255,65,0, 1.0)";
    }
  }

  function setupCanvasContext() {
    if (gcanvas.getContext) {
      gctx = gcanvas.getContext( '2d' );
      gctx.globalCompositeOperation = "source-over";
      gctx.lineWidth = lineWidth;
      gctx.fillStyle = canvasFillStyle;
      gctx.fillRect(0, 0, gcanvas.width, gcanvas.height);
      gctx.strokeStyle = "rgba(255,65,0, 1.0)";
    }
  }

  //
  // Update Canvas plotted data from [x, y] data points
  //
  function updateCanvasFromPoints(samplePoint) {
    var i, j, k,
        dx,
        px, py,
        index,
        yOrigin = yScale(0.00001),
        lines = options.lines,
        bars = options.bars,
        twopi = 2 * Math.PI,
        pointsLength,
        numberOfLines = pointArray.length,
        xAxisStart,
        xAxisEnd,
        pointStop,
        start,
        lengthX;

    // hack for lack of canvas support in jsdom tests
    if (typeof gcanvas.getContext === "undefined" ) { return; }

    setCurrentSample(samplePoint);
    clearCanvas();
    gctx.fillRect(0, 0, gcanvas.width, gcanvas.height);
    gctx.lineWidth = lineWidth;
    xAxisStart = xScale.domain()[0];
    xAxisEnd =   xScale.domain()[1];
    start = Math.max(0, xAxisStart);
    if (lines) {
      for (i = 0; i < numberOfLines; i++) {
        points = pointArray[i];
        pointsLength = points.length;
        if (pointsLength === 0) { break; }
        index = 0;
        // find first point >= xAxisStart
        for (j = 0; j < pointsLength; j++) {
          if (points[j][0] >= xAxisStart) { break; }
          index++;
        }
        if (index > 0) { --index; }
        if (index >= pointsLength) { break; }
        px = xScale(points[index][0]);
        py = yScale(points[index][1]);
        setStrokeColor(i);
        gctx.beginPath();
        gctx.moveTo(px, py);
        dx = points[index][0];
        index++;
        if (i < newDataSeries) {
          // plot all ... or until one point past xAxisEnd
          // or until we reach currentSample
          for (; index < samplePoint; index++) {
            dx = points[index][0];
            px = xScale(dx);
            py = yScale(points[index][1]);
            gctx.lineTo(px, py);
            if (dx >= xAxisEnd) { break; }
          }
          gctx.stroke();
          // now plot in a desaturated style all the rest of the points
          // ... or until one point past xAxisEnd
          if (index < pointsLength && dx < xAxisEnd) {
            setStrokeColor(i, true);
            gctx.lineWidth = lineWidth/2;
            for (;index < pointsLength; index++) {
              dx = points[index][0];
              px = xScale(dx);
              py = yScale(points[index][1]);
              gctx.lineTo(px, py);
              if (dx >= xAxisEnd) { break; }
            }
            gctx.stroke();
          }
        } else {
          // else we are plotting older complete datasets
          // plot all ... or until one point past xAxisEnd
          setStrokeColor(0, true);
          gctx.lineWidth = lineWidth/2;
          // temporary hack ...
          var previousPx = 0;
          for (; index < pointsLength-1; index++) {
            dx = points[index][0];
            px = xScale(dx);
            if (px < previousPx) { break; }
            previousPx = px;
            py = yScale(points[index][1]);
            gctx.lineTo(px, py);
            if (dx >= xAxisEnd) { break; }
          }
          gctx.stroke();
        }
      }
    } else if (bars) {
      for (i = 0; i < numberOfLines; i++) {
        points = pointArray[i];
        pointsLength = points.length;
        setStrokeColor(i);
        pointStop = samplePoint - 1;
        for (index=start; index < pointStop; index++) {
          px = xScale(points[index][0]);
          py = yScale(points[index][1]);
          if (py === 0) {
            continue;
          }
          gctx.beginPath();
          gctx.moveTo(px, yOrigin);
          gctx.lineTo(px, py);
          gctx.stroke();
        }
        pointStop = points.length-1;
        if (index < pointStop) {
          setStrokeColor(i, true);
          for (;index < pointStop; index++) {
            px = xScale(points[index][0]);
            py = yScale(points[index][1]);
            gctx.beginPath();
            gctx.moveTo(px, yOrigin);
            gctx.lineTo(px, py);
            gctx.stroke();
          }
        }
      }
    } else {
      for (i = 0; i < numberOfLines; i++) {
        points = pointArray[i];
        pointsLength = points.length;
        index = 0;
        // find first point >= xAxisStart
        for (j = 0; j < pointsLength; j++) {
          if (points[j][0] >= xAxisStart) { break; }
          index++;
        }
        if (index > 0) { --index; }
        if (index >= pointsLength) { break; }
        px = xScale(points[index][0]);
        py = yScale(points[index][1]);
        setFillColor(i);
        dx = points[index][0];
        index++;
        // plot all ... or until one point past xAxisEnd
        // or until we reach currentSample
        for (; index < samplePoint; index++) {
          dx = points[index][0];
          px = xScale(dx);
          py = yScale(points[index][1]);
          gctx.fillRect(px, py, lineWidth, lineWidth);
          if (dx >= xAxisEnd) { break; }
        }
        // now plot in a desaturated style all the rest of the points
        // ... or until one point past xAxisEnd
        if (index < pointsLength && dx < xAxisEnd) {
          setFillColor(i, true);
          for (;index < pointsLength; index++) {
            dx = points[index][0];
            px = xScale(dx);
            py = yScale(points[index][1]);
            gctx.fillRect(px, py, lineWidth, lineWidth);
            if (dx >= xAxisEnd) { break; }
          }
        }
      }
    }
  }

  function setStrokeColor(i, afterSamplePoint) {
    var opacity = afterSamplePoint ? 0.5 : 1.0;
    switch(i) {
      case 0:
        gctx.strokeStyle = "rgba(160,00,0," + opacity + ")";
        break;
      case 1:
        gctx.strokeStyle = "rgba(44,160,0," + opacity + ")";
        break;
      case 2:
        gctx.strokeStyle = "rgba(44,0,160," + opacity + ")";
        break;
      default:
        gctx.strokeStyle = "rgba(44,0,160," + opacity + ")";
        break;
    }
  }

  function setFillColor(i, afterSamplePoint) {
    var opacity = afterSamplePoint ? 0.4 : 1.0;
    switch(i) {
      case 0:
        gctx.fillStyle = "rgba(160,00,0," + opacity + ")";
        break;
      case 1:
        gctx.fillStyle = "rgba(44,160,0," + opacity + ")";
        break;
      case 2:
        gctx.fillStyle = "rgba(44,0,160," + opacity + ")";
        break;
      default:
        gctx.fillStyle = "rgba(44,0,160," + opacity + ")";
        break;
    }
  }

  // ------------------------------------------------------------
  //
  // Adding samples/data points
  //
  // ------------------------------------------------------------

  // Add an array of points then update the graph.
  function addPoints(datapoints) {
    newDataSeries = datapoints.length;
    addDataPoints(datapoints);
    setCurrentSample(points.length);
    updateOrRescale();
  }

  // Add an array of samples then update the graph.
  function addSamples(datasamples) {
    addDataSamples(datasamples);
    setCurrentSample(points.length);
    updateOrRescale();
  }


  // Add a point [x, y] by processing sample (Y value) synthesizing
  // X value from sampleInterval and number of points
  function addSample(sample) {
    var index = points.length,
        xvalue = (index + dataSampleStart) * sampleInterval,
        point = [ xvalue, sample ];
    points.push(point);
    setCurrentSample(points.length);
    updateOrRescale();
  }

  // Add a point [x, y] to points array
  function addPoint(pnt) {
    points.push(pnt);
    setCurrentSample(points.length);
    updateOrRescale();
  }

  // Add an array (or arrays) of points.
  function addDataPoints(datapoints) {
    if (Object.prototype.toString.call(datapoints[0]) === "[object Array]") {
      for (var i = 0; i < datapoints.length; i++) {
        points = pointArray[i];
        points.push.apply(points, [datapoints[i]]);
        pointArray[i] = points;
      }
      points = pointArray[0];
    } else {
      points.push.apply(points, datapoints);
      pointArray = [points];
    }
  }

  // Add an array of points by processing an array of samples (Y values)
  // synthesizing the X value from sampleInterval interval and number of points.
  function addDataSamples(datasamples) {
    var start,
        i;
    if (Object.prototype.toString.call(datasamples[0]) === "[object Array]") {
      for (i = 0; i < datasamples.length; i++) {
        if (!pointArray[i]) { pointArray.push([]); }
        points = pointArray[i];
        start = points.length * sampleInterval + dataSampleStart;
        points.push.apply(points, indexedData(datasamples[i], sampleInterval, start));
        pointArray[i] = points;
      }
      points = pointArray[0];
    } else {
      for (i = 0; i < datasamples.length; i++) {
        if (!pointArray[i]) { pointArray.push([]); }
        start = pointArray[i].length * sampleInterval + dataSampleStart;
        pointArray[i].push([start, datasamples[i]]);
      }
    }
  }

  function resetDataPoints(datapoints) {

    function copy(array) {
      var ret = [];
      array.forEach(function(element) {
        ret.push(element);
      });
      return ret;
    }

    pointArray = [];
    if (!datapoints || datapoints.length === 0) {
      points = [];
      pointArray = [points];
    } else if (Object.prototype.toString.call(datapoints[0]) === "[object Array]") {
      for (var i = 0; i < datapoints.length; i++) {
        pointArray.push(copy(datapoints[i]));
      }
      points = pointArray[0];
    } else {
      points = datapoints;
      pointArray = [copy(points)];
    }

    setCurrentSample(points.length - 1);
    cancelDomainShift();
  }

  function resetDataSamples(datasamples, interval, start) {
    pointArray = [];
    if (Object.prototype.toString.call(datasamples[0]) === "[object Array]") {
      for (var i = 0; i < datasamples.length; i++) {
        pointArray.push(indexedData(datasamples[i], interval, start));
      }
      points = pointArray[0];
    } else {
      points = indexedData(datasamples, interval, start);
      pointArray = [points];
    }
    sampleInterval = interval;
    dataSampleStart = start;
  }


  function resetSamples(datasamples) {
    resetDataSamples(datasamples, sampleInterval, dataSampleStart);
  }

  function deletePoint(i) {
    if (points.length) {
      points.splice(i, 1);
      if (currentSample >= points.length) {
        currentSample = points.length-1;
      }
    }
  }

  // ------------------------------------------------------------
  //
  // Keyboard Handling
  //
  // ------------------------------------------------------------

  function registerKeyboardHandler() {
    svg.node().addEventListener("keydown", function (evt) {
      if (!selected) return false;
      if (evt.type === "keydown") {
        switch (evt.keyCode) {
          case 8:   // backspace
          case 46:  // delete
          if (options.dataChange) {
            var i = points.indexOf(selected);
            deletePoint(i);
            selected = points.length ? points[i > 0 ? i - 1 : 0] : null;
            update();
          }
          evt.preventDefault();
          evt.stopPropagation();
          break;
        }
        evt.preventDefault();
      }
    });
  }

  // ------------------------------------------------------------
  //
  // Graph attribute updaters
  //
  // ------------------------------------------------------------

  // update the title
  function updateTitle() {
    if (options.title && title) {
      title.text(options.title);
    }
    renderGraph();
  }

  // update the x-axis label
  function updateXlabel() {
    if (options.xlabel && xlabel) {
      xlabel.text(options.xlabel);
    }
    renderGraph();
  }

  // update the y-axis label
  function updateYlabel() {
    if (options.ylabel && ylabel) {
      ylabel.text(options.ylabel);
    } else {
      ylabel.style("display", "none");
    }
    renderGraph();
  }

  // ------------------------------------------------------------
  //
  // Main API functions ...
  //
  // ------------------------------------------------------------

  function renderGraph() {
    calculateLayout();
    if (svg === undefined) {
      renderNewGraph();
    } else {
      repaintExistingGraph();
    }
    if (options.showButtons) {
      if (!buttonLayer) createButtonLayer();
      resizeButtonLayer();
    }
    redraw();
  }

  function reset(idOrElement, options, message) {
    if (arguments.length) {
      initialize(idOrElement, options, message);
    } else {
      initialize();
    }
    renderGraph();
    // and then render again using actual size of SVG text elements are
    renderGraph();
    redraw();
    registerKeyboardHandler();
    return api;
  }

  function resize(w, h) {
    scale(w, h);
    initializeLayout();
    renderGraph();
    redraw();
    return api;
  }

  //
  // Public API to instantiated Graph
  //
  api = {
    update:               update,
    repaint:              renderGraph,
    reset:                reset,
    redraw:               redraw,
    resize:               resize,
    notify:               notify,

    // selection brush api
    selectionDomain:      selectionDomain,
    selectionVisible:     selectionVisible,
    selectionListener:    selectionListener,
    selectionEnabled:     selectionEnabled,
    hasSelection:         hasSelection,

    /**
      Read only getter for the d3 selection referencing the DOM elements containing the d3
      brush used to implement selection region manipulation.
    */
    brushElement: function() {
      return brush_element;
    },

    /**
      Read-only getter for the d3 brush control (d3.svg.brush() function) used to implement
      selection region manipulation.
    */
    brushControl: function() {
      return brush_control;
    },

    /**
      Read-only getter for the internal listener to the d3 'brush' event.
    */
    brushListener: function() {
      return brushListener;
    },

    // specific update functions ???
    scale:                scale,
    updateOrRescale:      updateOrRescale,

    xDomain: function(_) {
      if (!arguments.length) return [options.xmin, options.xmax];
      options.xmin = _[0];
      options.xmax = _[1];
      if (updateXScale) {
        updateXScale();
        redraw();
      }
      return api;
    },

    yDomain: function(_) {
      if (!arguments.length) return [options.ymin, options.ymax];
      options.ymin = _[0];
      options.ymax = _[1];
      if (updateYScale) {
        updateYScale();
        redraw();
      }
      return api;
    },

    xmin: function(_) {
      if (!arguments.length) return options.xmin;
      options.xmin = _;
      options.xrange = options.xmax - options.xmin;
      if (updateXScale) {
        updateXScale();
        redraw();
      }
      return api;
    },

    xmax: function(_) {
      if (!arguments.length) return options.xmax;
      options.xmax = _;
      options.xrange = options.xmax - options.xmin;
      if (updateXScale) {
        updateXScale();
        redraw();
      }
      return api;
    },

    ymin: function(_) {
      if (!arguments.length) return options.ymin;
      options.ymin = _;
      options.yrange = options.ymax - options.ymin;
      if (updateYScale) {
        updateYScale();
        redraw();
      }
      return api;
    },

    ymax: function(_) {
      if (!arguments.length) return options.ymax;
      options.ymax = _;
      options.yrange = options.ymax - options.ymin;
      if (updateYScale) {
        updateYScale();
        redraw();
      }
      return api;
    },

    xLabel: function(_) {
      if (!arguments.length) return options.xlabel;
      options.xlabel = _;
      updateXlabel();
      return api;
    },

    yLabel: function(_) {
      if (!arguments.length) return options.ylabel;
      options.ylabel = _;
      updateYlabel();
      return api;
    },

    title: function(_) {
      if (!arguments.length) return options.title;
      options.title = _;
      updateTitle();
      return api;
    },

    width: function(_) {
      if (!arguments.length) return size.width;
      size.width = _;
      return api;
    },

    height: function(_) {
      if (!arguments.length) return size.height;
      size.height = _;
      return api;
    },

    elem: function(_) {
      if (!arguments.length) return elem;
      elem = d3.select(_);
      graph(elem);
      return api;
    },

    numberOfPoints: function() {
      if (points) {
        return points.length;
      } else {
        return false;
      }
    },

    // Point data consist of an array (or arrays) of [x,y] arrays.
    addPoints:       addPoints,
    addPoint:        addPoint,
    resetPoints:     resetDataPoints,

    // Sample data consists of an array (or an array or arrays) of samples.
    // The interval between samples is assumed to have already been set
    // by specifying options.sampleInterval when creating the graph.
    addSamples:      addSamples,
    addSample:       addSample,
    resetSamples: resetSamples

  };

  // Initialization.
  initialize(idOrElement, options, message);

  if (node) {
    renderGraph();
    // Render again using actual size of SVG text elements.
    renderGraph();
  }

  return api;
};
},{"./axis":1}],3:[function(require,module,exports){
module.exports = require('./lib/graph');

},{"./lib/graph":2}]},{},[3])
(3)
});
;

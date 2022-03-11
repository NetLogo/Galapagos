typedWidgetProperties = Object.freeze(new Map([
  ['button',   ['buttonKind', 'disableUntilTicksStart', 'forever', 'source']]
, ['chooser',  ['choices', 'display', 'variable']]
, ['inputBox', ['boxedValue', 'variable']]
, ['monitor',  ['display', 'fontSize', 'precision', 'source']]
, ['output',   ['fontSize']]
, ['plot',     ['autoPlotOn', 'display', 'legendOn', 'pens', 'setupCode', 'updateCode', 'xAxis', 'xmax', 'xmin', 'yAxis', 'ymax', 'ymin']]
, ['slider',   ['default', 'direction', 'display', 'max', 'min', 'step', 'units', 'variable']]
, ['switch',   ['display', 'on', 'variable']]
, ['textBox',  ['color', 'display', 'fontSize', 'transparent']]
, ['view',     ['dimensions', 'fontSize', 'frameRate', 'showTickCounter', 'tickCounterLabel', 'updateMode']]
]))

locationProperties = Object.freeze(['bottom', 'left', 'right', 'top'])

export { locationProperties, typedWidgetProperties }

# coffeelint: disable=max_line_length
typedWidgetProperties = Object.freeze(new Map([
  ['button',   ['actionKey', 'buttonKind', 'disableUntilTicksStart', 'display', 'forever', 'source']]
, ['chooser',  ['choices', 'currentChoice', 'display', 'variable']]
, ['inputBox', ['boxedValue', 'variable']]
, ['monitor',  ['display', 'fontSize', 'precision', 'source', 'units']]
, ['output',   ['fontSize']]
, ['plot',     ['autoPlotX', 'autoPlotY', 'display', 'legendOn', 'pens', 'setupCode', 'updateCode', 'xAxis', 'xmax', 'xmin', 'yAxis', 'ymax', 'ymin']]
, ['slider',   ['default', 'direction', 'display', 'max', 'min', 'step', 'units', 'variable']]
, ['switch',   ['display', 'on', 'variable']]
, ['textBox',  ['display', 'fontSize', 'markdown', 'backgroundLight', 'textColorLight', 'backgroundDark', 'textColorDark']]
, ['view',     ['dimensions', 'fontSize', 'frameRate', 'showTickCounter', 'tickCounterLabel', 'updateMode']]
]))
# coffeelint: enable=max_line_length

locationProperties = Object.freeze(['x', 'width', 'y', 'height'])

otherProperties = Object.freeze(['type', 'oldSize'])

# Care should be taken to *not* copy the `currentValue` for a monitor widget.
# That value can be a turtle or patch, which causes an infinite loop in the
# JSON serialization code due to circular references.  We've switched to
# only copying relevant properties over isntead of excluding "bad" properties,
# but I want to keep this note just in case someone decides it's better to
# switch back for some reason.

# Other widgets can also have a `currentValue` of a turtle or patch,
# sliders for sure, but that's a bug with the type checking not rejecting
# setting the global for the slider to an agent value.

# -Jeremy B July 2021 / March 2022

cloneWidget = (oldWidget) ->
  typeProperties = typedWidgetProperties.get(oldWidget.type)
  propertiesToCopy = Object.keys(oldWidget).filter( (p) ->
    typeProperties.includes(p) or
    locationProperties.includes(p) or
    otherProperties.includes(p)
  )
  propertiesToCopy.reduce( (newWidget, p) ->
    newWidget[p] = oldWidget[p]
    newWidget
  , {})

export { cloneWidget, locationProperties, typedWidgetProperties }

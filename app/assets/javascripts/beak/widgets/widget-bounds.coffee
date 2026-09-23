# (Ractive) => Array[Ractive]
widgetComponents = (root) ->
  root.findAllComponents().filter( (c) -> c.moveTo? and c.get('widget')? )

# (Ractive) => Rect
boundsOf = (component) ->
  { x: component.get('x'), y: component.get('y'), width: component.get('width'), height: component.get('height') }

export { widgetComponents, boundsOf }

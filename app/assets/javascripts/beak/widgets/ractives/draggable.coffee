import RactiveContextable from "./contextable.js"

# Ugh.  Single inheritance is a pox.  --Jason B. (10/29/17)
RactiveDraggableAndContextable = RactiveContextable.extend({

  data: -> {
    x: undefined # Number
  , y: undefined # Number
  }

  # (Number, Number) => Unit
  moveTo: (x, y) ->
    @set('x', x)
    @set('y', y)
    return

  # Subclasses that care when a move finishes override this.
  # () => Unit
  handleMoveEnd: ->
    return

  on: {

    'start-widget-drag': ({ node, original }) ->
      @fire('select-from-pointer', original)
      @fire('begin-widget-drag', node, original)
      return

  }

})

export {
  RactiveDraggableAndContextable
}

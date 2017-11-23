# All callers of this should have the properties `view: Element` and `lastUpdateMs: Number`,
# and these functions should be called with `call(<Ractive>, <args...>)` --JAB (11/23/17)
window.CommonDrag = {

  dragstart: ({ original: { clientX, clientY, dataTransfer, view } }, callback) ->

    invisiGIF = document.createElement('img')
    invisiGIF.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
    dataTransfer.setDragImage(invisiGIF, 0, 0)

    @view         = view
    @lastUpdateMs = (new Date).getTime()
    callback(clientX, clientY)

    return

  drag: ({ original: { clientX, clientY, view } }, callback) ->

    if @view?

      # When dragging stops, `client(X|Y)` tend to be very negative nonsense values
      # We only take non-negative values here, to avoid the widget disappearing --JAB (3/22/16, 10/29/17)

      # Only update drag coords 30 times per second.  If we don't throttle,
      # all of this `set`ing murders the CPU --JAB (10/29/17)
      if @view is view and clientX > 0 and clientY > 0 and ((new Date).getTime() - @lastUpdateMs) >= (1000 / 30)
        @lastUpdateMs = (new Date).getTime()
        callback(clientX, clientY)

    false

  dragend: (callback) ->

    if @view?

      @view         = undefined
      @lastUpdateMs = undefined

      callback()

    return


}

# Ugh.  Single inheritance is a pox.  --JAB (10/29/17)
window.RactiveDraggableAndContextable = RactiveContextable.extend({

  lastUpdateMs: undefined # Number
  startLeft:    undefined # Number
  startRight:   undefined # Number
  startTop:     undefined # Number
  startBottom:  undefined # Number
  view:         undefined # Element

  data: -> {
    left:      undefined # Number
  , right:     undefined # Number
  , top:       undefined # Number
  , bottom:    undefined # Number
  }

  on: {

    startWidgetDrag: (event) ->
      CommonDrag.dragstart.call(this, event, (x, y) =>
        @fire('selectComponent', event.component)
        @startLeft    = @get(  'left') - x
        @startRight   = @get( 'right') - x
        @startTop     = @get(   'top') - y
        @startBottom  = @get('bottom') - y
      )

    dragWidget: (event) ->
      CommonDrag.drag.call(this, event, (x, y) =>
        @set(  'left', @startLeft   + x)
        @set( 'right', @startRight  + x)
        @set(   'top', @startTop    + y)
        @set('bottom', @startBottom + y)
      )

    stopWidgetDrag: ->
      CommonDrag.dragend.call(this, =>
        @startLeft    = undefined
        @startRight   = undefined
        @startTop     = undefined
        @startBottom  = undefined
      )

  }

})

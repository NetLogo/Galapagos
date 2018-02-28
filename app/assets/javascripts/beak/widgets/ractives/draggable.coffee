# All callers of this should have the properties `view: Element` and `lastUpdateMs: Number`,
# and these functions should be called with `call(<Ractive>, <args...>)` --JAB (11/23/17)
window.CommonDrag = {

  dragstart: ({ original }, checkIsValid, callback) ->

    { clientX, clientY, dataTransfer, view } = original

    if checkIsValid(clientX, clientY)

      # The invisible GIF is used to hide the ugly "ghost" images that appear by default when dragging
      # The `setData` thing is done because, without it, Firefox feels that the drag hasn't really begun
      # So we give them some bogus drag data and get on with our lives. --JAB (11/22/17)
      invisiGIF = document.createElement('img')
      invisiGIF.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
      dataTransfer.setDragImage(invisiGIF, 0, 0)
      dataTransfer.setData('text/plain', '')

      @view         = view
      @lastUpdateMs = (new Date).getTime()
      callback(clientX, clientY)

    else

      original.preventDefault()
      false

    return

  drag: ({ original: { clientX, clientY, view } }, callback) ->

    if @view?

      # Thanks, Firefox! --JAB (11/23/17)
      root = ((r) -> if r.parent? then arguments.callee(r.parent) else r)(this)
      x    = if clientX isnt 0 then clientX else (root.get('lastDragX') ? -1)
      y    = if clientY isnt 0 then clientY else (root.get('lastDragY') ? -1)

      # When dragging stops, `client(X|Y)` tend to be very negative nonsense values
      # We only take non-negative values here, to avoid the widget disappearing --JAB (3/22/16, 10/29/17)

      # Only update drag coords 30 times per second.  If we don't throttle,
      # all of this `set`ing murders the CPU --JAB (10/29/17)
      if @view is view and x > 0 and y > 0 and ((new Date).getTime() - @lastUpdateMs) >= (1000 / 30)
        @lastUpdateMs = (new Date).getTime()
        callback(x, y)

    false

  dragend: (callback) ->

    if @view?

      root = ((r) -> if r.parent? then arguments.callee(r.parent) else r)(this)
      root.set('lastDragX', undefined)
      root.set('lastDragY', undefined)

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

    'start-widget-drag': (event) ->
      CommonDrag.dragstart.call(this, event, (-> true), (x, y) =>
        @fire('select-component', event.component)
        @startLeft    = @get(  'left') - x
        @startRight   = @get( 'right') - x
        @startTop     = @get(   'top') - y
        @startBottom  = @get('bottom') - y
      )

    'drag-widget': (event) ->
      CommonDrag.drag.call(this, event, (x, y) =>

        findAdjustment = (n) -> n - (Math.round(n / 5) * 5)

        xAdjust = findAdjustment(@startLeft + x)
        yAdjust = findAdjustment(@startTop  + y)

        @set(  'left', @startLeft   + x - xAdjust)
        @set( 'right', @startRight  + x - xAdjust)
        @set(   'top', @startTop    + y - yAdjust)
        @set('bottom', @startBottom + y - yAdjust)

      )

    'stop-widget-drag': ->
      CommonDrag.dragend.call(this, =>
        @startLeft    = undefined
        @startRight   = undefined
        @startTop     = undefined
        @startBottom  = undefined
      )

  }

})

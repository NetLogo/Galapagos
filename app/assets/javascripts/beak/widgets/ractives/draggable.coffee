import RactiveContextable from "./contextable.js"

# The `ractive` argument should have the properties `view: Element` and `lastUpdateMs: Number`.
# --JAB (11/23/17), David D. 7/2021
CommonDrag = {

  dragstart: (ractive, { original }, checkIsValid, callback) ->

    { clientX, clientY, dataTransfer, view } = original

    if checkIsValid(clientX, clientY)

      # The invisible GIF is used to hide the ugly "ghost" images that appear by default when dragging
      # The `setData` thing is done because, without it, Firefox feels that the drag hasn't really begun
      # So we give them some bogus drag data and get on with our lives. --JAB (11/22/17)
      invisiGIF = document.createElement('img')
      invisiGIF.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
      dataTransfer.setDragImage?(invisiGIF, 0, 0)
      dataTransfer.setData('text/plain', '')

      ractive.view         = view
      ractive.lastUpdateMs = (new Date).getTime()
      callback(clientX, clientY)

    else

      original.preventDefault()
      false

    return

  drag: (ractive, { original: { clientX, clientY, view } }, callback) ->
    if ractive.view?

      # Thanks, Firefox! --JAB (11/23/17)
      root = (findRoot = (r) -> if r.parent? then findRoot(r.parent) else r)(ractive)
      x    = if clientX isnt 0 then clientX else (root.get('lastDragX') ? -1)
      y    = if clientY isnt 0 then clientY else (root.get('lastDragY') ? -1)

      # When dragging stops, `client(X|Y)` tend to be very negative nonsense values
      # We only take non-negative values here, to avoid the widget disappearing --JAB (3/22/16, 10/29/17)

      # Only update drag coords 60 times per second.  If we don't throttle,
      # all of this `set`ing murders the CPU --JAB (10/29/17)
      if ractive.view is view and x > 0 and y > 0 and ((new Date).getTime() - ractive.lastUpdateMs) >= (1000 / 60)
        ractive.lastUpdateMs = (new Date).getTime()
        callback(x, y)

    true

  dragend: (ractive, callback) ->

    if ractive.view?

      root = (findRoot = (r) -> if r.parent? then findRoot(r.parent) else r)(ractive)
      root.set('lastDragX', undefined)
      root.set('lastDragY', undefined)

      ractive.view         = undefined
      ractive.lastUpdateMs = undefined

      callback()

    return


}

# Ugh.  Single inheritance is a pox.  --JAB (10/29/17)
RactiveDraggableAndContextable = RactiveContextable.extend({

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

  nudge: (direction) ->
    switch direction
      when "up"    then if @get('top')  > 0 then @set('top' , @get('top' ) - 1); @set('bottom', @get('bottom') - 1)
      when "down"  then                          @set('top' , @get('top' ) + 1); @set('bottom', @get('bottom') + 1)
      when "left"  then if @get('left') > 0 then @set('left', @get('left') - 1); @set('right' , @get('right' ) - 1)
      when "right" then                          @set('left', @get('left') + 1); @set('right' , @get('right' ) + 1)
      else              console.log("'#{direction}' is an impossible direction for nudging...")

  on: {

    'start-widget-drag': (event) ->
      CommonDrag.dragstart(this, event, (-> true), (x, y) =>
        @fire('select-component', event.component)
        @startLeft    = @get(  'left') - x
        @startRight   = @get( 'right') - x
        @startTop     = @get(   'top') - y
        @startBottom  = @get('bottom') - y
      )

    'drag-widget': (event) ->

      isMac      = window.navigator.platform.startsWith('Mac')
      isSnapping = ((not isMac and not event.original.ctrlKey) or (isMac and not event.original.metaKey))

      CommonDrag.drag(this, event, (x, y) =>

        findAdjustment = (n) -> n - (Math.round(n / 5) * 5)

        xAdjust = if isSnapping then findAdjustment(@startLeft + x) else 0
        yAdjust = if isSnapping then findAdjustment(@startTop  + y) else 0

        newLeft = @startLeft + x - xAdjust
        newTop  = @startTop  + y - yAdjust

        if newLeft < 0
          @set( 'left', 0)
          @set('right', @startRight - @startLeft)
        else
          @set( 'left', newLeft)
          @set('right', @startRight + x - xAdjust)

        if newTop < 0
          @set(   'top', 0)
          @set('bottom', @startBottom - @startTop)
        else
          @set(   'top', newTop)
          @set('bottom', @startBottom + y - yAdjust)

      )

    'stop-widget-drag': ->
      CommonDrag.dragend(this, =>
        @startLeft    = undefined
        @startRight   = undefined
        @startTop     = undefined
        @startBottom  = undefined
      )

  }

})

export {
  CommonDrag,
  RactiveDraggableAndContextable,
}

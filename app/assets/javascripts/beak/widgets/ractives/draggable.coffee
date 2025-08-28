import RactiveContextable from "./contextable.js"

# The `ractive` argument should have the properties `view: Element` and `lastUpdateMs: Number`.
# --Jason B. (11/23/17), David D. 7/2021
CommonDrag = {

  dragstart: (ractive, { original }, checkIsValid, callback) ->

    { clientX, clientY, dataTransfer, view } = original

    if checkIsValid(clientX, clientY)

      # The invisible GIF is used to hide the ugly "ghost" images that appear by
      # default when dragging.  The `setData` thing is done because, without it,
      # Firefox feels that the drag hasn't really begun, so we give them some bogus
      # drag data and get on with our lives. --Jason B. (11/22/17)
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

      # Thanks, Firefox! --Jason B. (11/23/17)

      # Firefox now throws in some weird negative values for clientX/clientY when the drag event occurs in an iframe
      # instead of just uselessly setting `0` (which is still does outside of an iframe?).  Hopefully other browsers are
      # still more sensible.  -Jeremy B January 2024

      root = (findRoot = (r) -> if r.parent? then findRoot(r.parent) else r)(ractive)
      x    = if clientX > 0 then clientX else (root.get('lastDragX') ? -1)
      y    = if clientY > 0 then clientY else (root.get('lastDragY') ? -1)

      # When dragging stops, `client(X|Y)` tend to be very negative nonsense values
      # We only take non-negative values here, to avoid the widget disappearing
      # --Jason B. (3/22/16, 10/29/17)

      # Only update drag coords 60 times per second.  If we don't throttle,
      # all of this `set`ing murders the CPU --Jason B. (10/29/17)
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

# Ugh.  Single inheritance is a pox.  --Jason B. (10/29/17)
RactiveDraggableAndContextable = RactiveContextable.extend({

  lastUpdateMs: undefined # Number
  startX:       undefined # Number
  startY:       undefined # Number
  lastX:        undefined # Number
  lastY:        undefined # Number
  view:         undefined # Element

  data: -> {
    x: undefined # Number
  , y: undefined # Number
  }

  nudge: (direction) ->
    switch direction
      when "up"    then if @get('y') > 0 then @set('y', @get('y') - 1)
      when "down"  then                       @set('y', @get('y') + 1)
      when "left"  then if @get('x') > 0 then @set('x', @get('x') - 1)
      when "right" then                       @set('x', @get('x') + 1)
      else              console.log("'#{direction}' is an impossible direction for nudging...")

  on: {

    'start-widget-drag': (event) ->
      CommonDrag.dragstart(this, event, (-> true), (x, y) =>
        @fire('select-component', event.component)
        @lastX  = @get('x')
        @lastY  = @get('y')
        @startX = @lastX - x
        @startY = @lastY - y
      )

    'drag-widget': (event) ->

      isMac      = window.navigator.platform.startsWith('Mac')
      isSnapping = ((not isMac and not event.original.ctrlKey) or (isMac and not event.original.metaKey))

      CommonDrag.drag(this, event, (x, y) =>

        fineAdjustment = (n) -> n - (Math.round(n / 5) * 5)

        xAdjust = if isSnapping then fineAdjustment(@startX + x) else 0
        yAdjust = if isSnapping then fineAdjustment(@startY + y) else 0

        newX = @startX + x - xAdjust
        newY = @startY + y - yAdjust

        # In Chromium, the very last drag event when the mouse button is released inside an iframe *sometimes* produces
        # garbage values when the screen is scrolled away from top+left.  Rather than updating with the recent drag
        # event we just got, we store it for next time and use the last one stored, ensuring we always skip the very
        # last drag event.  The drag events occur pretty frequently, so there is very little chance of dropping things
        # in the wrong spot.  -Jeremy B August 2025
        updateX = @lastX
        updateY = @lastY

        @lastX = newX
        @lastY = newY

        if updateX < 0
          @set('x', 0)
        else
          @set('x', updateX)

        if updateY < 0
          @set('y', 0)
        else
          @set('y', updateY)

      )

    'stop-widget-drag': ->
      CommonDrag.dragend(this, =>
        @startX = undefined
        @startY = undefined
        @lastX  = undefined
        @lastY  = undefined
      )

  }

})

export {
  CommonDrag,
  RactiveDraggableAndContextable
}

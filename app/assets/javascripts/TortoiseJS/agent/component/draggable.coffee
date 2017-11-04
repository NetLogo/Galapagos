# Ugh.  Single inheritance is a pox.  --JAB (10/29/17)
window.RactiveDraggableAndContextable = RactiveContextable.extend({

  startLeft:   undefined # Number
  startRight:  undefined # Number
  startTop:    undefined # Number
  startBottom: undefined # Number
  view:        undefined # Element

  data: -> {
    left:      undefined # Number
  , right:     undefined # Number
  , top:       undefined # Number
  , bottom:    undefined # Number
  , isEditing: undefined # Boolean
  }

  on: {

    startWidgetDrag: (event) ->

      { original: { clientX, clientY, dataTransfer, view } } = event

      if @get('isEditing')

        @fire('selectComponent', event.component)

        invisiGIF = document.createElement('img')
        invisiGIF.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
        dataTransfer.setDragImage(invisiGIF, 0, 0)

        @view         = view
        @startLeft    = @get(  'left') - clientX
        @startRight   = @get( 'right') - clientX
        @startTop     = @get(   'top') - clientY
        @startBottom  = @get('bottom') - clientY
        @lastUpdateMs = (new Date).getTime()

      return

    stopWidgetDrag: ->
      if @view?
        @view         = undefined
        @startLeft    = undefined
        @startRight   = undefined
        @startTop     = undefined
        @startBottom  = undefined
        @lastUpdateMs = undefined
      return

    dragWidget: ({ original: { clientX, clientY, view } }) ->

      if @view?

        # When dragging stops, `client(X|Y)` tend to be very negative nonsense values
        # We only take non-negative values here, to avoid the widget disappearing --JAB (3/22/16, 10/29/17)

        # Only update drag coords 30 times per second.  If we don't throttle,
        # all of this `set`ing murders the CPU --JAB (10/29/17)
        if @view is view and clientX > 0 and clientY > 0 and ((new Date).getTime() - @lastUpdateMs) >= (1000 / 30)
          @set(  'left', @startLeft   + clientX)
          @set( 'right', @startRight  + clientX)
          @set(   'top', @startTop    + clientY)
          @set('bottom', @startBottom + clientY)
          @lastUpdateMs = (new Date).getTime()

      false

  }

})


RactiveModal = Ractive.extend({
  data: {
    title: undefined      # String
    , id: undefined       # String
    , posX: 0             # Number
    , posY: 0             # Number
    , isDragging: false   # Boolean
    , lastClientX: 0      # Number
    , lastClientY: 0      # Number
    , containerWidth: "90vw"                         # String
    , containerHeight: "min(90vh, max(600px, 60vw))" # String
  },

  resizeObserver: undefined,

  on: {
    render: ->
      countResizes = 0
      if not @resizeObserver?
        @resizeObserver = new ResizeObserver((entries) =>
          # The first resize overrides the initial sizing
          # -Omar I, Aug 12, 2025
          countResizes += 1
          if countResizes < 2
            return

          for entry in entries
            # `px` indicates that the user resize has been applied
            # otherwise, we want to preserve the initial sizing
            # -Omar I, Aug 12, 2025
            if not entry.target.style.width? or not entry.target.style.height?
              continue
            if entry.target.style.width.includes('px')
              @set('containerWidth', "#{entry.contentRect.width}px")
            if entry.target.style.height.includes('px')
              @set('containerHeight', "#{entry.contentRect.height}px")
        )

        @resizeObserver.observe(@find('.netlogo-modal-container'))
      
      return

    teardown: ->
      if @resizeObserver?
        @resizeObserver.disconnect()
        @resizeObserver = undefined
      return

    "start-drag": (event) ->
      event.original.preventDefault()

      @set('isDragging', true)
      @set('lastClientX', event.original.clientX)
      @set('lastClientY', event.original.clientY)

      modalCls = this

      move = (event) ->
        event.preventDefault()
        if modalCls.get('isDragging')
          dx = event.clientX - modalCls.get('lastClientX')
          dy = event.clientY - modalCls.get('lastClientY')

          modalCls.set('posX', modalCls.get('posX') + dx)
          modalCls.set('posY', modalCls.get('posY') + dy)

          modalCls.set('lastClientX', event.clientX)
          modalCls.set('lastClientY', event.clientY)
      
      stop = () ->
        modalCls.set('isDragging', false)
        modalCls.set('lastClientX', 0)
        modalCls.set('lastClientY', 0)

        window.removeEventListener('mousemove', move)
        window.removeEventListener('mouseup', stop)
        window.removeEventListener('touchmove', move)
        window.removeEventListener('touchend', stop)
        window.removeEventListener('touchcancel', stop)

      window.addEventListener('mousemove', move)
      window.addEventListener('mouseup', stop)
      window.addEventListener('touchmove', move)
      window.addEventListener('touchend', stop)
      window.addEventListener('touchcancel', stop)


      return
  },

  computed: {
    top: ->
      "calc(50% + #{@get('posY')}px)"
    
    left: ->
      "calc(50% + #{@get('posX')}px)"

    resize: ->
      if @get('isDragging')
        "none"
      else
        "both"

    contentPointerEvents: ->
      if @get('isDragging')
        "none"
      else
        "auto"
  }

  template: """
  <div id={{id}} class="netlogo-modal-container" role="dialog"
     style="width: {{containerWidth}}; height: {{containerHeight}}; top: {{top}}; left: {{left}}; resize: {{resize}};">
     <div class="netlogo-modal-title"
     on-mousedown="['start-drag']"
     on-touchstart="['start-drag']"
     role="heading"
     >
      {{title}}
     </div>
     <div class="netlogo-modal-content"
        style="pointer-events: {{contentPointerEvents}};">
      {{yield}}
    </div>
  </div>
  """
})

export default RactiveModal

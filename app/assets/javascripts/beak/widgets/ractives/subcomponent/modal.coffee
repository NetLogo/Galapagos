
import startPointerDrag from "../../pointer-drag.js"

RactiveModal = Ractive.extend({
  data: {
    title: undefined      # String
    , id: undefined       # String
    , posX: 0             # Number
    , posY: 0             # Number
    , isDragging: false   # Boolean
    , isMouseDown: false  # Boolean
    , containerWidth: "90vw"                         # String
    , containerHeight: "min(90vh, max(600px, 60vw))" # String
    , minHeight: "200px"                      # String
    , minWidth:  "300px"                      # String
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

          if @get('isDragging')
            return

          if not @get('isMouseDown')
            return

          for entry in entries
            # `px` indicates that the user resize has been applied
            # otherwise, we want to preserve the initial sizing
            # -Omar I, Aug 12, 2025
            if not entry.target.style.width? or not entry.target.style.height?
              continue
            fontSize = parseFloat(getComputedStyle(document.documentElement).fontSize)
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

    "start-drag": ({ node, original }) ->
      startX = undefined
      startY = undefined

      startPointerDrag(node, original, {

        onStart: =>
          startX = @get('posX')
          startY = @get('posY')
          @set('isDragging', true)
          return

        onMove: ({ dx, dy }) =>
          @set({ posX: startX + dx, posY: startY + dy })
          return

        onEnd: =>
          @set('isDragging', false)
          return

      })

      return

    "mouse-down": (event) ->
      @set('isMouseDown', true)
      return

    "mouse-up": (event) ->
      @set('isMouseDown', false)
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

    containerStyle: ->
      Object.entries({
        width: @get('containerWidth')
        , height: @get('containerHeight')
        , "min-width": @get('minWidth')
        , "min-height": @get('minHeight')
        , top: @get('top')
        , left: @get('left')
        , resize: @get('resize')
      }).map(([key, value]) -> "#{key}: #{value};").join(" ")
  }

  template: """
  <div id={{id}} class="netlogo-modal-container"
       role="dialog"
       style="{{containerStyle}}"
       on-pointerdown="['mouse-down']"
       on-pointerup="['mouse-up']"
       >
     <div class="netlogo-modal-title"
          on-pointerdown="['start-drag']"
          role="heading"
     >
      <div class="netlogo-modal-top-bar-container">
        <div class="netlogo-modal-title-text">{{title}}</div>
      </div>
     </div>
     <div class="netlogo-modal-content"
        style="pointer-events: {{contentPointerEvents}};">
      {{yield}}
    </div>
  </div>
  """
})

export default RactiveModal

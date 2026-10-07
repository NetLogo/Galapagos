import startPointerDrag from "/beak/widgets/pointer-drag.js"

id = -1
nextId = () ->
  id = id + 1
  id

DRAG_KEEP_VISIBLE = 60

RactiveModalDialog = Ractive.extend({

  # type EventOptions = {
  #   text: String
  # , event: String | null
  # , target: Ractive | null
  # , arguments: Any[] | null
  # , argsMaker: () => Any[] | null
  # }

  data: () -> {
    id:               nextId()
  , active:           false           # Boolean
  , preRenderContent: false           # Boolean
  , left:             0               # Int
  , top:              50              # Int
  , approve:          { text: "Yes" } # EventOptions
  , showApprove:      true            # Boolean
  , deny:             { text: "No"  } # EventOptions
  , extraClasses:     null            # String
  }

  # () => Unit
  show: (top = 50, left = 50) ->
    @set("left", left)
    @set("top", top)
    @set("active", true)
    return

  on: {

    'render': () ->
      window.addEventListener('keyup', ({ key }) =>
        if key is 'Escape' and @get('active')
          @fire('fire-event', {}, 'deny')
        return
      )
      return

    # (Event, String) => Unit
    'fire-event': (_, eventId) ->
      @set("active", false)
      eventOptions = @get(eventId)
      if eventOptions? and eventOptions.event?
        args   = eventOptions.arguments ? eventOptions.argsMaker?() ? []
        target = eventOptions.target ? this
        target.fire(eventOptions.event, {}, ...args)
      return

    'start-drag': ({ node, original }) ->
      startLeft = undefined
      startTop  = undefined

      startPointerDrag(node, original, {

        onStart: =>
          startLeft = @get('left')
          startTop  = @get('top')
          return

        onMove: ({ dx, dy }) =>
          elem    = @find('.ntb-dialog')
          homeX   = elem.offsetLeft - @get('left')
          homeY   = elem.offsetTop  - @get('top')
          minLeft = DRAG_KEEP_VISIBLE - elem.offsetWidth - homeX
          maxLeft = elem.offsetParent.clientWidth - DRAG_KEEP_VISIBLE - homeX
          @set({
            left: Math.min(maxLeft, Math.max(minLeft, startLeft + dx))
          , top:  Math.max(-homeY, startTop + dy)
          })
          return

      })

      return

  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div
      class="ntb-dialog-overlay {{extraClasses}}"
      on-keyup="check-escape"
      {{# !active }}hidden{{/}}
      >
      <div
        class="ntb-dialog"
        style="left: {{left}}px; top: {{top}}px;"
        >

        {{# active || preRenderContent }}

        <div class="ntb-dialog-header" dir="auto" on-pointerdown="start-drag">
          {{> headerContent }}
        </div>

        <div class="ntb-dialog-content">
          {{> dialogContent }}
        </div>

        {{/}}

        <div class="ntb-dialog-buttons">

          {{# showApprove }}
          <input
            id="ntb-{{id}}-approve-button"
            class="widget-edit-text ntb-dialog-button"
            type="button"
            on-click="[ 'fire-event', 'approve' ]"
            value="{{ approve.text }}"
            >
          {{/ showApprove }}

          <input
            id="ntb-{{id}}-deny-button"
            class="widget-edit-text ntb-dialog-button"
            type="button"
            on-click="[ 'fire-event', 'deny' ]"
            value="{{ deny.text }}"
            >

        </div>

      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})

export default RactiveModalDialog

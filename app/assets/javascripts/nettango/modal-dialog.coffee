import { CommonDrag } from "/beak/widgets/ractives/draggable.js"

id = -1
nextId = () ->
  id = id + 1
  id

checkIsValidDragElement = (x, y) ->
  elem = document.elementFromPoint(x, y)
  switch elem.tagName.toLowerCase()
    when "input"    then elem.type.toLowerCase() isnt "number" and elem.type.toLowerCase() isnt "text"
    when "textarea" then false
    else                 true

RactiveModalDialog = Ractive.extend({

  lastUpdateMs: undefined # Number - used only by CommonDrag
  leftStart:    undefined # Int
  topStart:     undefined # Int
  view:         undefined # Element - used only by CommonDrag

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

    'start-drag': (event) ->
      CommonDrag.dragstart(this, event, checkIsValidDragElement, (x, y) =>
        @leftStart = @get('left') - x
        @topStart  = @get('top') - y
      )
      return

    'drag-dialog': (event) ->
      CommonDrag.drag(this, event, (x, y) =>
        @set('left', @leftStart + x)
        @set('top',  @topStart + y)
      )
      return

    'stop-drag': ->
      CommonDrag.dragend(this, (->))
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
        draggable="true"
        on-drag="drag-dialog"
        on-dragstart="start-drag"
        on-dragend="stop-drag"
        >

        {{# active || preRenderContent }}

        <div class="ntb-dialog-header" dir="auto">
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

dialogs = []

window.RactiveOnTopDialog = Ractive.extend({

  startX: undefined # Number
  startY: undefined # Number
  view:   undefined # Element

  data: -> {
    isMinimized: undefined # Boolean
  ,       style: undefined # String
  ,        xLoc: undefined # Number
  ,        yLoc: undefined # Number
  ,      zIndex: undefined # Number
  }

  components: {
    spacer: RactiveEditFormSpacer
  }

  isolated: true

  twoway: false

  oninit: ->

    dialogs.push(this)

    @on('focus'
    , ->
        elem = @find('*')
        elem.focus()
        @set('zIndex', Math.floor(100 + window.performance.now()))
    )

    @on('showYourself'
    , ->

        elem = @find('*')
        @fire('focus')

        # We don't want to reposition if it's already visible --JAB (7/25/16)
        if elem.classList.contains('hidden')

          # Must unhide before measuring and focusing --JAB (3/21/16)
          elem.classList.remove('hidden')
          elem.focus()

          containerMidX = @el.offsetWidth  / 2
          containerMidY = @el.offsetHeight / 2

          dialogHalfWidth  = elem.offsetWidth  / 2
          dialogHalfHeight = elem.offsetHeight / 2

          @set('xLoc', containerMidX - dialogHalfWidth)
          @set('yLoc', containerMidY - dialogHalfHeight)

        false

    )

    @on('activateCloakingDevice'
    , ->
        @find('*').classList.add('hidden')
        false
    )

    @on('startDialogDrag'
    , ({ original: { clientX, clientY, dataTransfer, view } }) ->

        # The drag image looks god-awful, so we create an invisible GIF to replace it. --JAB (8/11/16)
        img     = document.createElement('img')
        img.src = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='

        dataTransfer.effectAllowed = "move"
        dataTransfer.setDragImage(img, 0, 0)

        @view   = view
        @startX = @get('xLoc') - clientX
        @startY = @get('yLoc') - clientY

        return

    )

    @on('stopDialogDrag'
    , ->
        @view = undefined
        return
    )

    @on('dragDialog'
    , ({ original: { clientX, clientY, view } }) ->
        # When dragging stops, `client(X|Y)` tend to be very negative nonsense values
        # We only take non-negative values here, to avoid the dialog disappearing --JAB (3/22/16)
        if @view is view and clientX > 0 and clientY > 0
          rect        = this.find('*').getBoundingClientRect()
          bufferSpace = 30
          @set('xLoc', Math.max(0 - (rect.width  - bufferSpace), @startX + clientX))
          @set('yLoc', Math.max(0 - (rect.height - bufferSpace), @startY + clientY))
        false
    )

    @on('closeDialog'
    , ->

        @fire('activateCloakingDevice')

        visibleDialogs = dialogs.filter((d) -> not d.find('*').classList.contains('hidden'))
        if visibleDialogs.length > 0
          getZ = (d) -> parseInt(d.get('zIndex'))
          foremostDialog = visibleDialogs.reduce((best, d) -> if getZ(best) >= getZ(d) then best else d)
          foremostDialog.fire('focus')

        return
    )

    @on('handleKey'
    , ({ original: { keyCode } }) ->
        if keyCode is 27
          @fire('closeDialog')
          false
        return
    )

    return

  template:
    """
    <div class="netlogo-modal-popup hidden"
         style="top: {{yLoc}}px; left: {{xLoc}}px; {{style}}; {{ # zIndex }} z-index: {{zIndex}} {{/}}"
         on-keydown="handleKey" on-mousedown="focus" tabindex="0">
      <div class="netlogo-dialog-title-strip" draggable="true"
           {{ # isMinimized }}style="border-radius: 5px;"{{/}}
           on-drag="dragDialog" on-dragstart="startDialogDrag"
           on-dragend="stopDialogDrag">
        <div class="netlogo-dialog-title vertically-centered">
          {{>title}}
        </div>
        <div class="netlogo-dialog-nav-options">
          <div class="netlogo-dialog-nav-option" on-click="toggle('isMinimized')">{{ # !isMinimized }}–{{ else }}+{{/}}</div>
          <spacer width="8px" />
          <div class="netlogo-dialog-nav-option" on-click="closeDialog">X</div>
        </div>
      </div>
      <div style="margin: 7px 10px 0 10px; {{ # isMinimized }}display: none;{{/}}">
        {{>innerContent}}
      </div>
    </div>
    """

  partials: {
    innerContent: ""
  }

})

window.EditForm = RactiveOnTopDialog.extend({

  isolated: true

  twoway: false

  # We make the bound values lazy and then call `resetPartial` when showing, so as to
  # prevent the perpetuation of values after a change-and-cancel. --JAB (4/1/16)
  lazy: true

  oninit: ->

    @_super()

    @on('submit'
    , ({ node }) ->
        newProps = @validate(node)
        if newProps?
          @fire('updateWidgetValue', newProps)
        @fire('activateCloakingDevice')
        false
    )

    @on('showYourself'
    , ->
        @resetPartial('widgetFields', @partials.widgetFields)
    )

    return

  partials: {
    innerContent:
      """
      <form class="widget-edit-form" on-submit="submit">
        {{>widgetFields}}
        <div class="widget-edit-form-button-container">
          <input class="widget-edit-text" type="submit" value="OK" />
          <input class="widget-edit-text" type="button" on-click="closeDialog" value="Cancel" />
        </div>
      </form>
      """
    widgetFields: undefined
  }

})

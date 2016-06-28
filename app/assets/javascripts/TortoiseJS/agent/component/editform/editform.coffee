window.RactiveModalDialog = Ractive.extend({

  startX:    undefined # Number
  startY:    undefined # Number
  view:      undefined # Element

  data: -> {
    style:   undefined # String
  , xLoc:    undefined # Number
  , yLoc:    undefined # Number
  }

  isolated: true

  twoway: false

  oninit: ->

    @on('showYourself'
    , ->

        containerMidX = @el.offsetWidth  / 2
        containerMidY = @el.offsetHeight / 2

        # Must unhide before measuring --JAB (3/21/16)
        elem = @find('*')
        elem.classList.remove('hidden')
        elem.focus()

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
    , ({ original: { clientX, clientY, view } }) ->
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
          @set('xLoc', @startX + clientX)
          @set('yLoc', @startY + clientY)
        false
    )

    @on('closeDialog'
    , ->
        @fire('activateCloakingDevice')
        return
    )

    @on('handleKey'
    , ({ original: { keyCode } }) ->
        if keyCode is 27
          @fire('closeDialog')
          false
        return
    )

    @on('blockContextMenu'
    , ({ original }) ->
        original.preventDefault()
        false
    )

    return

  template:
    """
    <div class="netlogo-modal-popup hidden"
         style="top: {{yLoc}}px; left: {{xLoc}}px; {{style}};"
         on-contextmenu="blockContextMenu" on-keydown="handleKey"
         on-drag="dragDialog" on-dragstart="startDialogDrag"
         on-dragend="stopDialogDrag"
         tabindex="0">
      <div class="widget-edit-closer" on-click="closeDialog">X</div>
      {{>innerContent}}
    </div>
    """

  partials: {
    innerContent: ""
  }

})

window.EditForm = RactiveModalDialog.extend({

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
        <div class="netlogo-dialog-title">{{>title}}</div>
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

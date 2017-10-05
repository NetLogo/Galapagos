window.EditForm = Ractive.extend({

  startX:    undefined # Number
  startY:    undefined # Number
  view:      undefined # Element

  data: -> {
    idBasis: undefined # String
  , visible: undefined # Boolean
  , xLoc:    undefined # Number
  , yLoc:    undefined # Number
  }

  computed: {
    id: (-> "#{@get('idBasis')}-edit-window") # () => String
  }

  twoway: false

  # We make the bound values lazy and then call `resetPartials` when showing, so as to
  # prevent the perpetuation of values after a change-and-cancel. --JAB (4/1/16)
  lazy: true

  oninit: ->

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

        findParentByClass =
          (clss) -> ({ parentElement: parent }) ->
            if parent?
              if parent.classList.contains(clss)
                parent
              else
                findParentByClass(clss)(parent)
            else
              undefined

        # Must unhide before measuring --JAB (3/21/16)
        @set('visible', true)
        elem = @getElem()
        elem.focus()

        container     = findParentByClass('netlogo-widget-container')(elem)
        containerMidX = container.offsetWidth  / 2
        containerMidY = container.offsetHeight / 2

        dialogHalfWidth  = elem.offsetWidth  / 2
        dialogHalfHeight = elem.offsetHeight / 2

        @set('xLoc', containerMidX - dialogHalfWidth)
        @set('yLoc', containerMidY - dialogHalfHeight)

        @resetPartial('widgetFields', @partials.widgetFields)

        false

    )

    @on('activateCloakingDevice'
    , ->
        @set('visible', false)
        false
    )

    @on('startEditDrag'
    , ({ original: { clientX, clientY, view } }) ->
        @view   = view
        @startX = @get('xLoc') - clientX
        @startY = @get('yLoc') - clientY
        return
    )

    @on('stopEditDrag'
    , ->
        @view = undefined
        return
    )

    @on('dragEditDialog'
    , ({ original: { clientX, clientY, view } }) ->
        # When dragging stops, `client(X|Y)` tend to be very negative nonsense values
        # We only take non-negative values here, to avoid the dialog disappearing --JAB (3/22/16)
        if @view is view and clientX > 0 and clientY > 0
          @set('xLoc', @startX + clientX)
          @set('yLoc', @startY + clientY)
        false
    )

    @on('cancelEdit'
    , ->
        @fire('activateCloakingDevice')
        return
    )

    @on('handleKey'
    , ({ original: { keyCode } }) ->
        if keyCode is 27
          @fire('cancelEdit')
          false
        return
    )

    @on('blockContextMenu'
    , ({ original }) ->
        original.preventDefault()
        false
    )

    return

  getElem: ->
    @find("##{@get('id')}")

  template:
    """
    {{# visible }}
    <div id="{{id}}"
         class="widget-edit-popup widget-edit-text"
         style="top: {{yLoc}}px; left: {{xLoc}}px;"
         on-contextmenu="blockContextMenu" on-keydown="handleKey"
         on-drag="dragEditDialog" on-dragstart="startEditDrag"
         on-dragend="stopEditDrag"
         tabindex="0">
      <div id="{{id}}-closer" class="widget-edit-closer" on-click="cancelEdit">X</div>
      <form class="widget-edit-form" on-submit="submit">
        <div class="widget-edit-form-title">{{>title}}</div>
        {{>widgetFields}}
        <div class="widget-edit-form-button-container">
          <input class="widget-edit-text" type="submit" value="OK" />
          <input class="widget-edit-text" type="button" on-click="cancelEdit" value="Cancel" />
        </div>
      </form>
    </div>
    {{/}}
    """

  partials: {
    widgetFields: undefined
  }

})

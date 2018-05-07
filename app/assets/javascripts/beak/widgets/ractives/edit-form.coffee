window.EditForm = Ractive.extend({

  lastUpdateMs: undefined # Number
  startX:       undefined # Number
  startY:       undefined # Number
  view:         undefined # Element

  data: -> {
    amProvingMyself: false     # Boolean
  , idBasis:         undefined # String
  , style:           undefined # String
  , visible:         undefined # Boolean
  , xLoc:            undefined # Number
  , yLoc:            undefined # Number
  }

  computed: {
    id: (-> "#{@get('idBasis')}-edit-window") # () => String
  }

  twoway: false

  # We make the bound values lazy and then call `resetPartials` when showing, so as to
  # prevent the perpetuation of values after a change-and-cancel. --JAB (4/1/16)
  lazy: true

  on: {

    submit: ({ node }) ->
      try
        newProps = @genProps(node)
        if newProps?
          @fire('update-widget-value', {}, newProps)
      finally
        @set('amProvingMyself', false)
        @fire('activate-cloaking-device')
        return false

    'show-yourself': ->

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

      @fire(  'lock-selection', @parent)
      @fire('edit-form-opened', this)

      container     = findParentByClass('netlogo-widget-container')(elem)
      containerMidX = container.offsetWidth  / 2
      containerMidY = container.offsetHeight / 2

      dialogHalfWidth  = elem.offsetWidth  / 2
      dialogHalfHeight = elem.offsetHeight / 2

      @set('xLoc', containerMidX - dialogHalfWidth)
      @set('yLoc', containerMidY - dialogHalfHeight)

      @resetPartial('widgetFields', @partials.widgetFields)

      false

    'activate-cloaking-device': ->
      @set('visible', false)
      @fire('unlock-selection')
      @fire('edit-form-closed', this)
      if @get('amProvingMyself')
        @fire('has-been-proven-unworthy')
      false

    'prove-your-worth': ->
      @fire('show-yourself')
      @set('amProvingMyself', true)
      false

    'start-edit-drag': (event) ->
      checkIsValid = (x, y) ->
        elem = document.elementFromPoint(x, y)
        switch elem.tagName.toLowerCase()
          when "input"    then elem.type.toLowerCase() isnt "number" and elem.type.toLowerCase() isnt "text"
          when "textarea" then false
          else                 true
      CommonDrag.dragstart.call(this, event, checkIsValid, (x, y) =>
        @startX = @get('xLoc') - x
        @startY = @get('yLoc') - y
      )

    'drag-edit-dialog': (event) ->
      CommonDrag.drag.call(this, event, (x, y) =>
        @set('xLoc', @startX + x)
        @set('yLoc', @startY + y)
      )

    'stop-edit-drag': ->
      CommonDrag.dragend.call(this, (->))

    'cancel-edit': ->
      @fire('activate-cloaking-device')
      return

    'handle-key': ({ original: { keyCode } }) ->
      if keyCode is 27
        @fire('cancel-edit')
        false
      return

  }

  getElem: ->
    @find("##{@get('id')}")

  template:
    """
    {{# visible }}
    <div class="widget-edit-form-overlay">
      <div id="{{id}}"
           class="widget-edit-popup widget-edit-text"
           style="top: {{yLoc}}px; left: {{xLoc}}px; {{style}}"
           on-keydown="handle-key"
           draggable="true" on-drag="drag-edit-dialog" on-dragstart="start-edit-drag"
           on-dragend="stop-edit-drag"
           tabindex="0">
        <div id="{{id}}-closer" class="widget-edit-closer" on-click="cancel-edit">X</div>
        <form class="widget-edit-form" on-submit="submit">
          <div class="widget-edit-form-title">{{>title}}</div>
          {{>widgetFields}}
          <div class="widget-edit-form-button-container">
            <input class="widget-edit-text" type="submit" value="OK" />
            <input class="widget-edit-text" type="button" on-click="cancel-edit" value="Cancel" />
          </div>
        </form>
      </div>
    </div>
    {{/}}
    """

  partials: {
    widgetFields: undefined
  }

})

import startPointerDrag from "../pointer-drag.js"
import { getAllFocusableElements } from "../accessibility/utils.js"

# How much of a dragged form must stay inside the frame, in pixels.
DRAG_KEEP_VISIBLE = 60

EditForm = Ractive.extend({

  _formModelElem: undefined # Element
  _formMinYLoc:   undefined # Number
  _formResizeObserver: undefined # ResizeObserver

  data: -> {
    parentClass:     'netlogo-widget-container' # String
  , submitLabel:     'OK'       # String
  , cancelLabel:     'Cancel'   # String
  , horizontalOffset: undefined # Number
  , verticalOffset:   undefined # Number
  , amProvingMyself:  false     # Boolean
  , idBasis:          undefined # String
    # Entries are `{ message, start, end, field }` from the compiler, but older/non-compiler failures are bare strings.
    # -Jeremy B September 2026
  , compileErrors:    undefined # Array[{ message: String } | String]
  , style:            undefined # String
  , visible:          undefined # Boolean
  , xLoc:             undefined # Number
  , yLoc:             undefined # Number
  }

  computed: {
    id: (-> "#{@get('idBasis')}-edit-window") # () => String
  }

  twoway: false

  # We make the bound values lazy and then call `resetPartials` when showing,
  # so as to prevent the perpetuation of values after a change-and-cancel.
  # --Jason B. (4/1/16)
  lazy: true

  on: {

    submit: ({ node }) ->
      try
        newProps = @genProps(node)
        if newProps?
          @fire('update-widget-value', {}, newProps, @get('amProvingMyself'))
      catch ex
        console.warn("Widget form submission error: ", ex)
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

      # Must unhide before measuring --Jason B. (3/21/16)
      @set('visible', true)
      elem = @getElem()
      elem.focus()

      setTimeout(=>
        focusableElements = getAllFocusableElements(elem)
        if focusableElements.length > 0
          focusableElements[0].focus()
      , 0)

      @fire(  'lock-selection', @parent)
      @fire('edit-form-opened', this)

      container = findParentByClass(@get('parentClass'))(elem)
      modelElem = findParentByClass('netlogo-model')(elem)

      # Render the fields before measuring.  This used to come last, so a tall form (a plot's, especially) was measured
      # at whatever height it had before its fields existed, and the model below was grown by too little -- leaving the
      # OK button off the bottom of the frame.  -Jeremy B September 2026
      @resetPartial('widgetFields', @partials.widgetFields)

      containerMidX = container.offsetWidth  / 2
      containerMidY = container.offsetHeight / 2

      dialogHalfWidth  = elem.offsetWidth  / 2
      dialogHalfHeight = elem.offsetHeight / 2

      minYLoc = if modelElem?
        modelElem.getBoundingClientRect().top - elem.parentElement.getBoundingClientRect().top
      else
        0

      finalYLoc = Math.max(minYLoc, @get('verticalOffset') ? (containerMidY - dialogHalfHeight))

      @set('xLoc', @get('horizontalOffset') ? (containerMidX - dialogHalfWidth))
      @set('yLoc', finalYLoc)

      if modelElem?
        @_formModelElem = modelElem
        @_formMinYLoc   = minYLoc
        @fitModelToForm()
        if window.ResizeObserver?
          @_formResizeObserver = new ResizeObserver( () => @fitModelToForm(); return )
          @_formResizeObserver.observe(elem)

      false

    'activate-cloaking-device': ->
      @_formResizeObserver?.disconnect()
      @_formResizeObserver = undefined
      if @_formModelElem?
        @_formModelElem.style.minHeight = ''
        @_formModelElem = undefined
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

    # Only the title bar drags the form, so the fields below it can still be scrolled, selected, and typed in.
    'start-edit-drag': ({ node, original }) ->
      startX = undefined
      startY = undefined

      startPointerDrag(node, original, {

        onStart: =>
          startX = @get('xLoc')
          startY = @get('yLoc')
          return

        onMove: ({ dx, dy }) =>
          # The pointer is captured, so it can leave the frame.  Keep the title bar where it can be grabbed again.
          elem = @getElem()
          maxX = elem.offsetParent.clientWidth - DRAG_KEEP_VISIBLE
          minX = DRAG_KEEP_VISIBLE - elem.offsetWidth
          minY = @_formMinYLoc ? 0
          @set({
            xLoc: Math.min(maxX, Math.max(minX, startX + dx))
          , yLoc: Math.max(minY, startY + dy)
          })
          return

        onEnd: =>
          # Dragging changes `yLoc`, so the model has to grow (or shrink) to match the form's new bottom edge.
          @fitModelToForm()
          return

      })

      return

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

  # () => Unit
  fitModelToForm: ->
    elem = @getElem()
    if @_formModelElem? and elem?
      @_formModelElem.style.minHeight = "#{(@get('yLoc') ? 0) - (@_formMinYLoc ? 0) + elem.offsetHeight}px"
    return

  template:
    """
    {{# visible }}
    <div class="widget-edit-form-overlay">
      <div id="{{id}}"
           class="widget-edit-popup widget-edit-text"
           style="top: {{yLoc}}px; left: {{xLoc}}px; {{style}}"
           on-keydown="handle-key"
           tabindex="0">
        <div id="{{id}}-closer" class="widget-edit-closer" on-click="cancel-edit">X</div>
        <form class="widget-edit-form" on-submit="submit">
          <div class="widget-edit-form-title" on-pointerdown="start-edit-drag">{{>title}}</div>
          {{# compileErrors.length > 0 }}
            <div class="widget-edit-errors">
              {{#each compileErrors}}
                <div class="widget-edit-error">{{ .message || . }}</div>
              {{/each}}
            </div>
          {{/}}
          {{>widgetFields}}
          <div class="widget-edit-form-button-container">
            <input class="widget-edit-text" type="submit" value="{{ submitLabel }}" />
            <input class="widget-edit-text" type="button" on-click="cancel-edit" value="{{ cancelLabel }}" />
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

export default EditForm

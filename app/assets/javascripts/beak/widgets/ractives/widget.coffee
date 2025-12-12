import keywords                           from "/keywords.js"
import { RactiveDraggableAndContextable } from "./draggable.js"

WidgetEventGenerators = {

  # (String, String, Object[String]) => WidgetEvent
  recompileForPlot: (oldName, newName, renamings) ->
    {
      run:  (ractive, widget) -> ractive.fire('recompile-for-plot', 'system', oldName, newName, renamings)
      type: "recompile-for-plot"
    }

  recompile: ->
    {
      run:  (ractive, widget) -> ractive.fire('recompile', 'system')
      type: "recompile"
    }

  redrawView: ->
    {
      run:  (ractive, widget) -> ractive.fire('redraw-view')
      type: "redrawView"
    }

  refreshChooser: ->
    {
      # For whatever reason, if Ractive finds second argument of `fire` to be an
      # object (in this case, our `widget`), it merges that arg into the context
      # and ruins everything. --Jason B. (4/8/18)
      run: (ractive, widget) -> ractive.fire('refresh-chooser', "ignore", widget)
      type: "refreshChooser"
    }

  rename: (oldName, newName) ->
    {
      run:  (ractive, widget) -> ractive.fire('rename-interface-global', oldName, newName, widget.currentValue)
      type: "rename:#{oldName},#{newName}"
    }

  resizePatches: ->
    {
      run:  (ractive, widget) -> ractive.fire('set-patch-size', widget.dimensions.patchSize)
      type: "resizePatches"
    }

  resizeView: ->
    {
      run:  (ractive, widget) -> ractive.fire('resize-view')
      type: "resizeView"
    }

  updateEngineValue: ->
    {
      run: (ractive, widget) -> world.observer.setGlobal(widget.variable, widget.currentValue)
      type: "updateCurrentValue"
    }

  updateTopology: ->
    {
      run:  (ractive, widget) -> ractive.fire('update-topology')
      type: "updateTopology"
    }

}

RactiveWidget = RactiveDraggableAndContextable.extend({

  _weg: WidgetEventGenerators

  data: -> {
    id:         undefined # String
  , isEditing:  undefined # Boolean
  , isSelected: undefined # Boolean
  , resizeDirs: ['left', 'right', 'top', 'bottom', 'topLeft', 'topRight', 'bottomLeft', 'bottomRight']
  , widget:     undefined # Widget
  }

  components: {
    editForm: undefined # Element
  }

  computed: {
    classes: ->
      """
      #{if @get('isEditing')  then 'interface-unlocked' else ''}
      #{if @get('isSelected') then 'selected'           else ''}
      """

    dims: ->
      """
      position: absolute;
      left: #{@get('x')}px; top: #{@get('y')}px;
      width: #{@get('width')}px; height: #{@get('height')}px;
      """

    # Number (Positive Integer)
    tabIndexEnabledValue: ->
      @get('widget.sortingKey') + 1

    # Number (-1 | Positive Integer)
    tabindex: ->
      if @get('isEditing') then -1 else @get('tabIndexEnabledValue')

    # Number (-1 | Positive Integer)
    editorTabindex: ->
      if @get('isEditing') then @get('tabIndexEnabledValue') else -1

    # String
    ariaLabel: ->
      "Widget #{@get('widget.id')} (#{@get('widget.type')})"

    # String
    attrs: ->
      [ "tabindex=\"#{@get('tabindex')}\"",
        "aria-label=\"#{@get('ariaLabel')}\"",
      ].join(' ')
  }

  notifyWidgetMoved: () ->
    widget = @get('widget')
    @fire('widget-moved', widget.id, widget.type, widget.y, widget.height, widget.x, widget.width)
    return

  nudge: (direction) ->
    @_super(direction)
    @notifyWidgetMoved()
    return

  # (Object[Number]) => Unit
  handleResize: ({ x, width, y, height }) ->
    @set('widget.x'     , x)
    @set('widget.width' , width)
    @set('widget.y'     , y)
    @set('widget.height', height)
    return

  # () => Unit
  handleResizeEnd: ->
    @notifyWidgetMoved()
    return

  # (Widget) => Array[Any]
  getExtraNotificationArgs: (widget) ->
    []

  # (Ractive, (String, Ractive) => Unit) => Boolean
  _addNewTerm: (sender, finalizer) ->
    varName = prompt("New name:", "")
    if varName?
      if @_isValidIdentifier(varName)

        { globalVars, myVars, procedures } = @parent.get('metadata')
        globalNames      = globalVars.map((g) -> g.name)
        procNames        = procedures.map((p) -> p.name)
        takenIdentifiers = keywords.all.concat(globalNames, myVars, procNames)
        loweredTakens    = takenIdentifiers.map((ident) -> ident.toLowerCase())

        loweredName = varName.toLowerCase()

        if not loweredTakens.includes(loweredName)
          finalizer(varName, sender)
        else
          sender.fire('nlw-notify', "Name already in use!")

      else
        sender.fire('nlw-notify', "Not a valid NetLogo identifier!")

    false

  # (String, Ractive) => Unit
  _defineNewBreedVar: (varName, sender) ->
    @set('breedVars', [varName].concat(@get('breedVars')))
    sender.fire('use-new-var', varName)
    @fire('new-breed-var', varName)

  # (String) => Boolean
  _isValidIdentifier: (ident) ->
    letters = "a-z"
    digits  = "0-9"
    symbols = "_\\-!#\\$%\\^&\\*<>/\\.\\?=\\+:'"
    (new RegExp("^[#{letters}#{symbols}][#{letters}#{digits}#{symbols}]*$")).test(ident)

  on: {

    'edit-widget': ->
      if @get('isNotEditable') isnt true
        @fire('hide-context-menu')
        @findComponent('editForm').fire("show-yourself")
        false
      return

    '*.edit-form-closed': ->
      # 'edit-form-closed' may be fired before the DOM element is rendered
      # so we need to check for DOM mount before trying to focus it.
      # - Omar I. (Oct 14 2025)
      if @el?
        # The skeleton forces the focus out of the widget when the edit form
        # closes *after* this callback runs, so we need to defer the focus call.
        # - Omar I. (Oct 14 2025)
        setTimeout((=>
          @find('.editor-overlay')?.focus({ preventScroll: true })
        ), 0)
      return

    init: ->
      @findComponent('editForm')?.fire("activate-cloaking-device")
      return

    'on-editor-overlay-keydown': (event, trueEvent) ->
      isTargetEditorOverlay =
        trueEvent.target is @find('.editor-overlay')

      isKeyEnter =
        trueEvent.key is 'Enter'

      if isTargetEditorOverlay and isKeyEnter and @get('isSelected')
        trueEvent.preventDefault()
        @fire('edit-widget')

      return

    'initialize-widget': ->
      @findComponent('editForm').fire("prove-your-worth")
      false

    # (, String | Undefined) => Unit
    'copy-current-value': (_, currentValue) ->
      widget = @get('widget')
      currentValue = currentValue or widget.currentValue?.toString() or ""
      try
        await navigator.clipboard.writeText(currentValue)
        NetLogoToaster.addToast({
          id: "copy-widget-value-#{Date.now()}",
          message: "Copied to clipboard: #{currentValue}",
          timeout: 3000
        })
      catch error
        NetLogoToaster.addToast({
          id: "copy-widget-value-failure-#{Date.now()}",
          variant: "error",
          message: "Failed to copy to clipboard.",
          timeout: 5000
        })
      return

    "*.add-breed-var": ({ component: sender }) ->
      @_addNewTerm(sender, (v, s) => @_defineNewBreedVar(v, s))

    "*.has-been-proven-unworthy": ->
      # Original event name: "cutMyLifeIntoPieces" --Jason B. (11/8/17)
      @fire('unregister-widget', @get('widget').id, true)

    "*.update-widget-value": (_, values, isNewWidget) ->

      getByPath = (obj) -> (path) ->
        path.split('.').reduce(((acc, x) -> acc[x]), obj)

      setByPath = (obj) -> (path) -> (value) ->
        [parents..., key] = path.split('.')
        lastParent = parents.reduce(((acc, x) -> acc[x]), obj)
        lastParent[key] = value

      try

        extras = values.__extras
        delete values.__extras

        widget = @get('widget')

        widgets       = Object.values(@parent.get('widgetObj'))
        isTroublesome = (w) -> w.variable is values.variable and w.type isnt widget.type

        if values.variable? and widgets.some(isTroublesome)
          @fire('reject-duplicate-var', values.variable)
        else

          scrapeWidget =
            (widget, triggerNames) ->
              triggerNames.reduce(((acc, x) -> acc[x] = getByPath(widget)(x); acc), {})

          triggers     = @eventTriggers()
          triggerNames = Object.keys(triggers)

          oldies = scrapeWidget(widget, triggerNames)

          for k, v of values
            setByPath(widget)(k)(v)

          newies = scrapeWidget(widget, triggerNames)

          eventArraysArray =
            for name in triggerNames when newies[name] isnt oldies[name]
              triggers[name].map((constructEvent) -> constructEvent(oldies[name], newies[name]))

          extraEvents =
            if extras?.recompileForPlot
              [WidgetEventGenerators.recompileForPlot()]
            else
              []

          events = [].concat(extraEvents, eventArraysArray...)

          uniqueEvents =
            events.reduce(((acc, x) -> if not acc.find((y) -> y.type is x.type)? then acc.concat([x]) else acc), [])

          # Special casing this feels a bit silly, but it works, and given the special casing for plots, I guess it's
          # par for the course.  Necessary because if the redraw happens before all changes are applied (topology and
          # world coordinates) then the unapplied stuff is lost.  -Jeremy B December 2023
          uniqueEvents.sort( (event1, event2) ->
            if (event1.type is 'redrawView') then 1 else if (event2.type is 'redrawView') then -1 else 0
          )

          for event in uniqueEvents
            realEvent =
              if event.type is "recompile-for-plot"
                editForm  = @findComponent('editForm')
                oldName   = editForm.getOldName()
                newName   = widget.display
                renamings = editForm.getRenamings()
                WidgetEventGenerators.recompileForPlot(oldName, newName, renamings)
              else
                event
            realEvent.run(this, widget)

          notifyEventName = if isNewWidget then 'new-widget-finalized' else 'widget-updated'
          @fire(notifyEventName, widget.id, widget.type, @getExtraNotificationArgs()...)

          @fire('update-widgets')

      catch ex
        console.error(ex)
      finally
        return false

    "*.stop-widget-drag": (_) ->
      @notifyWidgetMoved()

  }

  # coffeelint: disable=max_line_length
  partials: {
    editorOverlay:
      """
      {{ #isEditing }}
      <div
        draggable="true"
        style="{{dims}}"
        class="editor-overlay{{#isSelected}} selected{{/}}{{#widget.type === 'plot' || widget.type === 'hnwPlot'}} plot-overlay{{/}}"
        on-click="@this.fire('hide-context-menu') && @this.fire('select-widget', @event)"
        on-keydown="@this.fire('on-editor-overlay-keydown', @event)"
        on-contextmenu="@this.fire('show-context-menu', @event)"
        on-dblclick="@this.fire('edit-widget')"
        on-dragstart="start-widget-drag"
        on-drag="drag-widget"
        on-dragend="stop-widget-drag"
        on-focus="@this.fire('select-widget', @event)"
        on-blur="@this.fire('deselect-widgets')"
        on-copy="@this.fire('copy-current-value')"
        role="button"
        tabindex="{{editorTabindex}}"
        aria-label="Editable overlay for widget {{widget.id}} of type {{widget.type}}"
        >
      </div>
      {{/}}
      """
  }

})

export default RactiveWidget

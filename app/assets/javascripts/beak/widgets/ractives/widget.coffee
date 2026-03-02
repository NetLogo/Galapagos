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
      left: #{@get('left')}px; top: #{@get('top')}px;
      width: #{@get('right') - @get('left')}px; height: #{@get('bottom') - @get('top')}px;
      """
  }

  notifyWidgetMoved: () ->
    widget = @get('widget')
    @fire('widget-moved', widget.id, widget.type, widget.top, widget.bottom, widget.left, widget.right)
    return

  nudge: (direction) ->
    @_super(direction)
    @notifyWidgetMoved()
    return

  # (Object[Number]) => Unit
  handleResize: ({ left, right, top, bottom }) ->
    @set('widget.left'  , left  )
    @set('widget.right' , right )
    @set('widget.top'   , top   )
    @set('widget.bottom', bottom)
    return

  # () => Unit
  handleResizeEnd: ->
    @notifyWidgetMoved()
    return

  # (Widget) => Array[Any]
  getExtraNotificationArgs: (widget) ->
    []

  on: {

    'edit-widget': ->
      if @get('isNotEditable') isnt true
        @fire('hide-context-menu')
        @findComponent('editForm').fire("show-yourself")
        false
      return

    init: ->
      @findComponent('editForm')?.fire("activate-cloaking-device")
      return

    'initialize-widget': ->
      @findComponent('editForm').fire("prove-your-worth")
      false

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
        class="editor-overlay{{#isSelected}} selected{{/}}{{#widget.type === 'plot'}} plot-overlay{{/}}"
        on-click="@this.fire('hide-context-menu') && @this.fire('select-widget', @event)"
        on-contextmenu="show-context-menu"
        on-dblclick="@this.fire('edit-widget')"
        on-dragstart="start-widget-drag"
        on-drag="drag-widget"
        on-dragend="stop-widget-drag">
      </div>
      {{/}}
      """
  }

})

export default RactiveWidget

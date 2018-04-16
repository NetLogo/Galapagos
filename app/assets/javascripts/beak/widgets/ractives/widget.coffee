WidgetEventGenerators = {

  recompile: ->
    {
      run:  (ractive, widget) -> ractive.fire('recompile')
      type: "recompile"
    }

  recompileLite: ->
    {
      run:  (ractive, widget) -> ractive.fire('recompile-lite')
      type: "recompile-lite"
    }

  redrawView: ->
    {
      run:  (ractive, widget) -> ractive.fire('redraw-view')
      type: "redrawView"
    }

  refreshChooser: ->
    {
      # For whatever reason, if Ractive finds second argument of `fire` to be an object (in this case, our `widget`),
      # it merges that arg into the context and ruins everything. --JAB (4/8/18)
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

window.RactiveWidget = RactiveDraggableAndContextable.extend({

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

  # (Object[Number]) => Unit
  handleResize: ({ left, right, top, bottom }) ->
    @set('widget.left'  , left  )
    @set('widget.right' , right )
    @set('widget.top'   , top   )
    @set('widget.bottom', bottom)
    return

  # () => Unit
  handleResizeEnd: ->
    return

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
      @fire('unregister-widget', @get('widget').id, true) # Original event name: "cutMyLifeIntoPieces" --JAB (11/8/17)

    "*.update-widget-value": (_, values) ->

      getByPath = (obj) -> (path) ->
        path.split('.').reduce(((acc, x) -> acc[x]), obj)

      setByPath = (obj) -> (path) -> (value) ->
        [parents..., key] = path.split('.')
        lastParent = parents.reduce(((acc, x) -> acc[x]), obj)
        lastParent[key] = value

      try

        widget = @get('widget')

        widgets       = Object.values(this.parent.get('widgetObj'))
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

          events = [].concat(eventArraysArray...)

          uniqueEvents =
            events.reduce(((acc, x) -> if not acc.find((y) -> y.type is x.type)? then acc.concat([x]) else acc), [])

          for event in uniqueEvents
            event.run(this, widget)

          @fire('update-widgets')

      catch ex
        console.error(ex)
      finally
        return false

  }

  partials: {
    editorOverlay: """
                   {{ #isEditing }}
                     <div draggable="true" style="{{dims}}" class="editor-overlay{{#isSelected}} selected{{/}}"
                          on-click="@this.fire('hide-context-menu') && @this.fire('select-widget', @event)"
                          on-contextmenu="@this.fire('show-context-menu', @event)"
                          on-dblclick="@this.fire('edit-widget')"
                          on-dragstart="start-widget-drag"
                          on-drag="drag-widget"
                          on-dragend="stop-widget-drag"></div>
                   {{/}}
                   """
  }

})

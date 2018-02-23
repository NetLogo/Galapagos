window.RactiveWidget = RactiveDraggableAndContextable.extend({

  data: -> {
    id:         undefined # String
  , isEditing:  undefined # Boolean
  , resizeDirs: ['left', 'right', 'top', 'bottom', 'topLeft', 'topRight', 'bottomLeft', 'bottomRight']
  , widget:     undefined # Widget
  }

  components: {
    editForm: undefined # Element
  }

  computed: {
    dims: ->
      """
      position: absolute;
      left: #{@get('left')}px; top: #{@get('top')}px;
      width: #{@get('right') - @get('left')}px; height: #{@get('bottom') - @get('top')}px;
      """
  }

  on: {

    editWidget: ->
      if @get('isNotEditable') isnt true
        @fire('hideContextMenu')
        @findComponent('editForm').fire("showYourself")
        false
      return

    init: ->
      @findComponent('editForm')?.fire("activateCloakingDevice")
      return

    initializeWidget: ->
      @findComponent('editForm').fire("proveYourWorth")
      false

    "*.hasBeenProvenUnworthy": ->
      @fire('unregisterWidget', @get('widget').id) # Original event name: "cutMyLifeIntoPieces" --JAB (11/8/17)

    "*.updateWidgetValue": ({ triggers = {}, values = {}}) ->

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
          @fire('rejectDuplicateVar', values.variable)
        else

          triggerNames = Object.keys(triggers)

          oldies = triggerNames.reduce(((acc, x) -> acc[x] = getByPath(widget)(x); acc), {})

          for k, v of values
            setByPath(widget)(k)(v)

          eventArraysArray =
            for name in triggerNames when getByPath(widget)(name) isnt oldies[name]
              triggers[name].map((f) -> f(oldies[name], getByPath(widget)(name)))

          events = [].concat(eventArraysArray...)

          uniqueEvents =
            events.reduce(((acc, x) -> if not acc.find((y) -> y.type is x.type)? then acc.concat([x]) else acc), [])

          for event in uniqueEvents
            event.run(this, widget)

          @fire('updateWidgets')

      catch ex
        console.error(ex)
      finally
        return false

  }

  partials: {
    editorOverlay: """
                   {{ #isEditing }}
                     <div draggable="true" style="{{dims}} z-index: 50;"
                          on-click="@this.fire('hideContextMenu') && @this.fire('selectWidget', @event)"
                          on-contextmenu="@this.fire('showContextMenu', @event)"
                          on-dblclick="@this.fire('editWidget')"
                          on-dragstart="startWidgetDrag"
                          on-drag="dragWidget"
                          on-dragend="stopWidgetDrag"></div>
                   {{/}}
                   """
  }

})

window.WidgetEventGenerators = {

  recompile: ->
    {
      run:  (ractive, widget) -> ractive.fire('recompile')
      type: "recompile"
    }

  redrawView: ->
    {
      run:  (ractive, widget) -> ractive.fire('redraw-view')
      type: "redrawView"
    }

  refreshChooser: ->
    {
      run: (ractive, widget) -> ractive.fire('refresh-chooser', widget)
      type: "refreshChooser"
    }

  rename: (oldName, newName) ->
    {
      run:  (ractive, widget) -> ractive.fire('renameInterfaceGlobal', oldName, newName, widget.currentValue)
      type: "rename:#{oldName},#{newName}"
    }

  resizeView: ->
    {
      run:  (ractive, widget) -> ractive.fire('resize-view')
      type: "resizeView"
    }

  updateTopology: ->
    {
      run:  (ractive, widget) -> ractive.fire('update-topology')
      type: "updateTopology"
    }

}

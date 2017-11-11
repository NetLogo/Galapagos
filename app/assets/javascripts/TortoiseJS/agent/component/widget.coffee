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
      @fire('hideContextMenu')
      @findComponent('editForm').fire("showYourself")
      false

    init: ->
      @findComponent('editForm')?.fire("activateCloakingDevice")
      return

    initializeWidget: ->
      @findComponent('editForm').fire("proveYourWorth")
      false

    "*.hasBeenProvenUnworthy": ->
      @fire('unregisterWidget', @get('widget').id) # Original event name: "cutMyLifeIntoPieces" --JAB (11/8/17)

    "*.updateWidgetValue": (_, { proxies = {}, triggers = {}, values = {}}) ->

      getByPath = (obj) -> (path) ->
        path.split('.').reduce(((acc, x) -> acc[x]), obj)

      try

        widget = @get('widget')

        triggerNames = Object.keys(triggers)

        oldies = triggerNames.reduce(((acc, x) -> acc[x] = getByPath(widget)(x); acc), {})

        for k, v of values
          widget[k] = v

        for k, v of proxies
          widget.proxies[k] = v

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
        false

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

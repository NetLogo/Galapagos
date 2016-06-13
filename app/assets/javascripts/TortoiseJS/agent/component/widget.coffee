window.RactiveWidget = Ractive.extend({

  data: -> {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # Widget
  }

  components: {
    editForm: undefined # Element
  }

  isolated: true

  oninit: ->

    @findComponent('editForm')?.fire("activateCloakingDevice")

    @on('editWidget'
    , ->
        @fire('hideContextMenu')
        @findComponent('editForm').fire("showYourself")
        false
    )

    @on('*.updateWidgetValue'
    , ({ proxies = {}, triggers = {}, values = {}}) ->

        widget = @get('widget')

        triggerNames = Object.keys(triggers)

        oldies = triggerNames.reduce(((acc, x) -> acc[x] = widget[x]; acc), {})

        for k, v of values
          widget[k] = v

        for k, v of proxies
          widget.proxies[k] = v

        eventArraysArray =
          for name in triggerNames when widget[name] isnt oldies[name]
            triggers[name].map((f) -> f(oldies[name], widget[name]))

        events = [].concat(eventArraysArray...)

        uniqueEvents =
          events.reduce(((acc, x) -> if not acc.find((y) -> y.type is x.type)? then acc.concat([x]) else acc), [])

        for event in uniqueEvents
          event.run(this, widget)

        false

    )

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

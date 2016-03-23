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

    @findComponent('editForm').fire("activateCloakingDevice")

    @on('editWidget'
    , ->
        @fire('hideContextMenu')
        @findComponent('editForm').fire("showYourself")
        false
    )

    @on('*.updateWidgetValue'
    , (obj) ->

        widget    = @get('widget')
        startName = widget.varName

        for k, v of obj
          widget[k] = v

        endName = widget.varName

        if startName isnt endName
          @fire('renameInterfaceGlobal', startName, endName, widget.currentValue)
          @fire('recompile')

        false

    )

})

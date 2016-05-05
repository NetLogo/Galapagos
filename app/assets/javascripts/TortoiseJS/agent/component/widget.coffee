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
    , (obj) ->

        widget = @get('widget')

        { varName: startName, source: startSource, buttonType: startType } = widget

        for k, v of obj
          widget[k] = v

        { varName: endName, source: endSource, buttonType: endType } = widget

        didRename     =  startName   isnt endName
        didChangeCode = (startSource isnt endSource) or (startType isnt endType)

        if didRename
          @fire('renameInterfaceGlobal', startName, endName, widget.currentValue)

        if didRename or didChangeCode
          @fire('recompile')

        false

    )

})

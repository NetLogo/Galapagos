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

        {
          buttonType: startType
        ,        max: startMax
        ,        min: startMin
        ,     source: startSource
        ,       step: startStep
        ,    varName: startName
        } = widget

        for k, v of obj
          widget[k] = v

        {
          buttonType: endType
        ,        max: endMax
        ,        min: endMin
        ,     source: endSource
        ,       step: endStep
        ,    varName: endName
        } = widget

        didRename = startName isnt endName

        didChangeCode =
          (startMax    isnt endMax   ) or
          (startMin    isnt endMin   ) or
          (startSource isnt endSource) or
          (startStep   isnt endStep  ) or
          (startType   isnt endType  )

        if didRename
          @fire('renameInterfaceGlobal', startName, endName, widget.currentValue)

        if didRename or didChangeCode
          @fire('recompile')

        false

    )

})

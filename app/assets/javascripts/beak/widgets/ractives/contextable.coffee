RactiveContextable = Ractive.extend({

  # type ContextMenuOption = { text: String, isEnabled: Boolean, action: () => Unit }

  getStandardOptions: -> {
    delete: {
      text: "Delete"
    , isEnabled: true
    , action: =>
        @fire('hide-context-menu')
        widget = @get('widget')
        @fire('unregister-widget', widget.id, false, @getExtraNotificationArgs())
    }
  , edit: { text: "Edit", isEnabled: true, action: => @fire('edit-widget') }
  }

  # (number, number) -> [ContextMenuOption]
  getContextMenuOptions: (clientX, clientY) ->
    isEditing = @get('isEditing') ? false # the Ractive must have the `isEditing` property set to true
    if isEditing
      Object.values(@getStandardOptions())
    else
      []

})

export default RactiveContextable

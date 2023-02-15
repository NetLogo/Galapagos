RactiveContextable = Ractive.extend({

# type ContextMenuOptions = [{ text: String, isEnabled: Boolean, action: () => Unit }]

  data: -> {
    contextMenuOptions: undefined # ContextMenuOptions
  }

  standardOptions: (component) -> {
    delete: {
      text: "Delete"
    , isEnabled: true
    , action: ->
        component.fire('hide-context-menu')
        widget = component.get('widget')
        component.fire('unregister-widget', widget.id, false, component.getExtraNotificationArgs())
    }
  , edit: { text: "Edit", isEnabled: true, action: -> component.fire('edit-widget') }
  }

})

export default RactiveContextable

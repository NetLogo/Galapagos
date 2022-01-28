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
        component.fire('unregister-widget', component.get('widget').id, false)
    }
  , edit: { text: "Edit", isEnabled: true, action: -> component.fire('edit-widget') }
  }

})

export default RactiveContextable

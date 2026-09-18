RactiveContextable = Ractive.extend({

  # type ContextMenuOption = { text: String, isEnabled: Boolean, action: () => Unit }

  # () => Number
  _selectionSize: ->
    if @get('isSelected') then (@root.get('selectedWidgetCount') ? 1) else 1

  # () => Number
  _deletableSelectionSize: ->
    if @_selectionSize() > 1 then (@root.get('selectedDeletableCount') ? 0) else 1

  getStandardOptions: -> {
    edit: { text: "Edit", isEnabled: true, action: => @fire('edit-widget') }
  , delete: do =>
      isMultiple = @_selectionSize() > 1
      count      = @_deletableSelectionSize()
      {
        text:
          if not isMultiple
            "Delete"
          else if count is 1
            "Delete 1 Widget"
          else
            "Delete #{count} Widgets"
      , isEnabled: count > 0
      , action: =>
          @fire('hide-context-menu')
          if isMultiple
            @fire('delete-selected')
          else
            widget = @get('widget')
            @fire('unregister-widget', widget.id, false, @getExtraNotificationArgs())
      }
  }

  # (number, number) -> [ContextMenuOption]
  getContextMenuOptions: (clientX, clientY) ->
    isEditing = @get('isEditing') ? false
    if isEditing
      options = @getStandardOptions()
      if @_selectionSize() > 1 then [options.delete] else Object.values(options)
    else
      []

})

export default RactiveContextable

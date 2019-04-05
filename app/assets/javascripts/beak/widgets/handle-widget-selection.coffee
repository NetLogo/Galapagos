# (Ractive) => Unit
window.handleWidgetSelection =
  (ractive) ->

    resizer =
      ->
        ractive.findComponent('resizer')

    lockSelection =
      (_, component) ->
        resizer().lockTarget(component)
        return

    unlockSelection =
      ->
        resizer().unlockTarget()
        return

    deleteSelected =
      ->
        selected = resizer().get('target')
        if ractive.get('isEditing') and selected?
          widget            = selected.get('widget')
          hasNoEditWindowUp = not document.querySelector('.widget-edit-popup')?
          if widget? and (widget.type isnt "view") and hasNoEditWindowUp
            unlockSelection()
            deselectThoseWidgets()
            ractive.fire('unregister-widget', widget.id)
        return

    justSelectIt =
      (event) ->
        resizer().setTarget(event.component)
        return

    selectThatWidget =
      (event, trueEvent) ->
        if ractive.get("isEditing")
          trueEvent.preventDefault()
          trueEvent.stopPropagation()
          justSelectIt(event)
        return

    deselectThoseWidgets =
      ->
        resizer().clearTarget()
        return

    ractive.observe("isEditing"
    , (isEditing) ->
        deselectThoseWidgets()
        return
    )

    hideResizer =
      ->
        if ractive.get("isEditing")
          ractive.set('isResizerVisible', not ractive.get('isResizerVisible'))
          false
        else
          true

    nudgeWidget =
      (event, direction) ->
        selected = resizer().get('target')
        if selected? and (not ractive.get('someDialogIsOpen'))
          selected.nudge(direction)
          false
        else
          true

    ractive.on('*.select-component', justSelectIt)
    ractive.on('*.select-widget'   , selectThatWidget)
    ractive.on('deselect-widgets'  , deselectThoseWidgets)
    ractive.on('delete-selected'   , deleteSelected)
    ractive.on('hide-resizer'      , hideResizer)
    ractive.on('nudge-widget'      , nudgeWidget)
    ractive.on('*.lock-selection'  , lockSelection)
    ractive.on('*.unlock-selection', unlockSelection)

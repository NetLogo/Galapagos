# (Ractive) => Unit
handleWidgetSelection =
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
            ractive.fire('unregister-widget', widget.id, false, selected.getExtraNotificationArgs())
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

    # (KeyboardEvent, "up" | "down" | "left" | "right", Boolean) => Boolean
    nudgeWidget =
      (event, direction, nudgeFar) ->
        selected = resizer().get('target')
        if selected? and (not ractive.get('someDialogIsOpen'))
          repeatCount = if nudgeFar then 10 else 1
          direction   =
          for i in [1..repeatCount]
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

export default handleWidgetSelection

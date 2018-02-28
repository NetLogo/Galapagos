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
        selected          = resizer().get('target')
        widget            = selected.get('widget')
        hasNoEditWindowUp = not document.querySelector('.widget-edit-popup')?
        if ractive.get('isEditing') and selected? and widget? and (widget.type isnt "view") and hasNoEditWindowUp
          unlockSelection()
          deselectThoseWidgets()
          ractive.fire('unregister-widget', widget.id)
        return

    justSelectIt =
      (event) ->
        resizer().setTarget(event.component)

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

    ractive.on('*.select-component', justSelectIt)
    ractive.on('*.select-widget'   , selectThatWidget)
    ractive.on('deselect-widgets'  , deselectThoseWidgets)
    ractive.on('delete-selected'   , deleteSelected)
    ractive.on('*.lock-selection'  , lockSelection)
    ractive.on('*.unlock-selection', unlockSelection)

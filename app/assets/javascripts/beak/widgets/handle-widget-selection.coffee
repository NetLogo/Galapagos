import WidgetSelection from "./widget-selection.js"

isMac = window.navigator.platform.startsWith('Mac')

isTogglingSelection = (domEvent) ->
  domEvent? and (domEvent.shiftKey or (if isMac then domEvent.metaKey else domEvent.ctrlKey))

# (Ractive) => Unit
handleWidgetSelection =
  (ractive) ->

    resizer =
      ->
        ractive.findComponent('resizer')

    # (Ractive) => Boolean
    isDeletable =
      (component) ->
        widget = component.get('widget')
        widget? and (widget.type isnt "view")

    selection =
      new WidgetSelection( (components) ->
        ractive.set('selectedWidgetCount'   , components.length)
        ractive.set('selectedDeletableCount', components.filter(isDeletable).length)
        resizer()?.showFor(if components.length is 1 then components[0] else null)
        return
      )

    lockSelection =
      (_, component) ->
        if component? and not selection.has(component)
          selection.set(component)
        selection.lock()
        return

    unlockSelection =
      ->
        selection.unlock()
        return

    deleteSelected =
      ->
        if ractive.get('isEditing')
          selection.unlock()
          doomed            = selection.all().filter(isDeletable)
          hasNoEditWindowUp = not document.querySelector('.widget-edit-popup')?
          if doomed.length > 0 and hasNoEditWindowUp
            if doomed.length is 1 or window.confirm("Delete these #{doomed.length} widgets?")
              selection.clear()
              for component in doomed
                widget = component.get('widget')
                ractive.fire('unregister-widget', widget.id, false, component.getExtraNotificationArgs())
        return

    justSelectIt =
      (event) ->
        if not selection.has(event.component)
          selection.set(event.component)
        return

    isSelectingByPointer = false

    selectFromPointer =
      (event, domEvent) ->
        if ractive.get("isEditing") and (domEvent.button is 0)
          isSelectingByPointer = true
          setTimeout((-> isSelectingByPointer = false), 0)
          domEvent.stopPropagation()
          if isTogglingSelection(domEvent)
            selection.toggle(event.component)
          else if not selection.has(event.component)
            selection.set(event.component)
        return

    selectThatWidget =
      (event, trueEvent) ->
        if ractive.get("isEditing")
          trueEvent.preventDefault()
          trueEvent.stopPropagation()
          component = event.component
          if trueEvent.type is 'click'
            # A drag eats its own click, so a click arriving here means the press stayed put.  As on the desktop, that
            # narrows a multi-selection down to the widget that was clicked.
            if (not isTogglingSelection(trueEvent)) and (selection.size() > 1 or not selection.has(component))
              selection.set(component)
          else if (not isSelectingByPointer) and (not selection.has(component))
            selection.set(component)
        return

    deselectThoseWidgets =
      (_, domEvent) ->
        if not isTogglingSelection(domEvent)
          selection.clear()
        return

    ractive.observe("isEditing"
    , (isEditing) ->
        unlockSelection()
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
        selected = selection.all()
        if selected.length > 0 and (not ractive.get('someDialogIsOpen'))
          repeatCount = if nudgeFar then 10 else 1
          for i in [1..repeatCount]
            for component in selected
              component.nudge(direction)
          false
        else
          true

    ractive.on('*.select-component'   , justSelectIt)
    ractive.on('*.select-from-pointer', selectFromPointer)
    ractive.on('*.select-widget'      , selectThatWidget)
    ractive.on('deselect-widgets'     , deselectThoseWidgets)
    ractive.on('*.delete-selected'    , deleteSelected)
    ractive.on('hide-resizer'         , hideResizer)
    ractive.on('nudge-widget'         , nudgeWidget)
    ractive.on('*.lock-selection'     , lockSelection)
    ractive.on('*.unlock-selection'   , unlockSelection)

export default handleWidgetSelection

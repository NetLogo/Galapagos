import WidgetSelection  from "./widget-selection.js"
import startPointerDrag from "./pointer-drag.js"

import { rectFromCorners, rectsTouch } from "./rectangles.js"

isMac = window.navigator.platform.startsWith('Mac')

GRID_SIZE = 5

isTogglingSelection = (domEvent) ->
  domEvent? and (domEvent.shiftKey or (if isMac then domEvent.metaKey else domEvent.ctrlKey))

isFreeMoving = (domEvent) ->
  if isMac then domEvent.metaKey else domEvent.ctrlKey

# (Array[Ractive]) => Array[{ component: Ractive, x0: Number, y0: Number }]
snapshotPositions = (components) ->
  components.map( (component) -> { component, x0: component.get('x'), y0: component.get('y') } )

# (Array[{ x0: Number, y0: Number }], Number, Number) => [Number, Number]
clampGroupOffset = (starts, dx, dy) ->
  minX = Math.min(starts.map( ({ x0 }) -> x0 )...)
  minY = Math.min(starts.map( ({ y0 }) -> y0 )...)
  [Math.max(dx, -minX), Math.max(dy, -minY)]

# (Array[{ component: Ractive, x0: Number, y0: Number }], Number, Number) => Unit
moveGroupBy = (starts, dx, dy) ->
  for { component, x0, y0 } in starts
    component.moveTo(x0 + dx, y0 + dy)
  return

# (Array[{ component: Ractive, x0: Number, y0: Number }]) => Unit
finishGroupMove = (starts) ->
  for { component, x0, y0 } in starts when component.get('x') isnt x0 or component.get('y') isnt y0
    component.handleMoveEnd()
  return

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

    beginWidgetDrag =
      (event, node, domEvent) ->
        if ractive.get('isEditing')

          component = event.component
          starts    = []
          grabbed   = undefined

          startPointerDrag(node, domEvent, {

            onStart: ->
              if not selection.has(component)
                selection.set(component)
              starts  = snapshotPositions(selection.all())
              grabbed = starts.find( (start) -> start.component is component )
              return

            onMove: (info) ->
              if grabbed?
                snap       = (n) -> if isFreeMoving(info) then n else Math.round(n / GRID_SIZE) * GRID_SIZE
                [dx, dy]   = clampGroupOffset(starts
                                             , snap(grabbed.x0 + info.dx) - grabbed.x0
                                             , snap(grabbed.y0 + info.dy) - grabbed.y0)
                moveGroupBy(starts, dx, dy)
              return

            onEnd: ->
              finishGroupMove(starts)
              return

          })
        return

    # () => Array[Ractive]
    allWidgets =
      ->
        ractive.findAllComponents().filter( (c) -> c.moveTo? and c.get('widget')? )

    # (Ractive) => Rect
    boundsOf =
      (component) ->
        { x: component.get('x'), y: component.get('y'), width: component.get('width'), height: component.get('height') }

    beginBoxSelect =
      (event) ->
        domEvent  = event.original
        container = event.node
        if ractive.get('isEditing') and (domEvent.target is container)

          toLocal =
            ({ clientX, clientY }) ->
              { left, top } = container.getBoundingClientRect()
              [clientX - left, clientY - top]

          [startX, startY] = toLocal(domEvent)
          keptWidgets      = []

          startPointerDrag(container, domEvent, {

            onStart: (info) ->
              keptWidgets = if isTogglingSelection(info) then selection.all() else []
              return

            onMove: (info) ->
              [x, y] = toLocal(info)
              box    = rectFromCorners(startX, startY, x, y)
              ractive.set('selectionBox', box)
              touched = allWidgets().filter( (c) -> rectsTouch(box, boundsOf(c)) )
              selection.replace(keptWidgets.concat(touched))
              return

            onEnd: ->
              ractive.set('selectionBox', null)
              return

          })
        return

    selectAllWidgets =
      ->
        if ractive.get('isEditing')
          selection.replace(allWidgets())
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
          distance = if nudgeFar then 10 else 1
          [wantX, wantY] =
            switch direction
              when "up"    then [        0, -distance]
              when "down"  then [        0,  distance]
              when "left"  then [-distance,         0]
              when "right" then [ distance,         0]
              else
                console.log("'#{direction}' is an impossible direction for nudging...")
                [0, 0]
          starts   = snapshotPositions(selected)
          [dx, dy] = clampGroupOffset(starts, wantX, wantY)
          moveGroupBy(starts, dx, dy)
          finishGroupMove(starts)
          false
        else
          true

    ractive.on('*.begin-widget-drag'  , beginWidgetDrag)
    ractive.on('begin-box-select'     , beginBoxSelect)
    ractive.on('select-all-widgets'   , selectAllWidgets)
    ractive.on('*.select-from-pointer', selectFromPointer)
    ractive.on('*.select-widget'      , selectThatWidget)
    ractive.on('deselect-widgets'     , deselectThoseWidgets)
    ractive.on('*.delete-selected'    , deleteSelected)
    ractive.on('hide-resizer'         , hideResizer)
    ractive.on('nudge-widget'         , nudgeWidget)
    ractive.on('*.lock-selection'     , lockSelection)
    ractive.on('*.unlock-selection'   , unlockSelection)

export default handleWidgetSelection

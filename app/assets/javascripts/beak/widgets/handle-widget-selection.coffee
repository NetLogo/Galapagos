import WidgetSelection  from "./widget-selection.js"
import startPointerDrag from "./pointer-drag.js"

import { findSnap, edgesOf }                        from "./edge-snapping.js"
import { rectFromCorners, rectsTouch, boundingRect } from "./rectangles.js"
import { widgetComponents, boundsOf }               from "./widget-bounds.js"

isMac = window.navigator.platform.startsWith('Mac')

GRID_SIZE = 5

# (MouseEvent | DragInfo | undefined) => Boolean
isTogglingSelection = (domEvent) ->
  domEvent? and (domEvent.shiftKey or (if isMac then domEvent.metaKey else domEvent.ctrlKey))

# (DragInfo) => Boolean
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

    # () => Ractive | null
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

    # (Context, Ractive | undefined) => Unit
    lockSelection =
      (_, component) ->
        if component? and not selection.has(component)
          selection.set(component)
        selection.lock()
        return

    # () => Unit
    unlockSelection =
      ->
        selection.unlock()
        return

    # () => Unit
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

    # (Context, Element, PointerEvent) => Unit
    beginWidgetDrag =
      (event, node, domEvent) ->
        if ractive.get('isEditing')

          component  = event.component
          starts     = []
          grabbed    = undefined
          groupBox   = undefined
          candidates = undefined

          startPointerDrag(node, domEvent, {

            # () => Unit
            onStart: ->
              ractive.fire('hide-context-menu')
              if not selection.has(component)
                selection.set(component)
              selected   = selection.all()
              starts     = snapshotPositions(selected)
              grabbed    = starts.find( (start) -> start.component is component )
              groupBox   = boundingRect(selected.map(boundsOf))
              candidates = edgesOf(widgetComponents(ractive).filter( (c) -> not selection.has(c) ).map(boundsOf))
              return

            # (DragInfo) => Unit
            onMove: (info) ->
              if grabbed?
                if isFreeMoving(info)
                  [dx, dy] = clampGroupOffset(starts, info.dx, info.dy)
                  ractive.set('snapGuides', [])
                else
                  # (Number) => Number
                  gridSnap = (n) -> Math.round(n / GRID_SIZE) * GRID_SIZE
                  moved    = edgesOf([{ ...groupBox, x: groupBox.x + info.dx, y: groupBox.y + info.dy }])
                  snap     = findSnap(moved, candidates)
                  wantX    = if snap.x? then info.dx + snap.x.delta else gridSnap(grabbed.x0 + info.dx) - grabbed.x0
                  wantY    = if snap.y? then info.dy + snap.y.delta else gridSnap(grabbed.y0 + info.dy) - grabbed.y0
                  [dx, dy] = clampGroupOffset(starts, wantX, wantY)
                  guides   = []
                  if snap.x? and dx is wantX
                    guides.push({ axis: 'x', at: snap.x.at })
                  if snap.y? and dy is wantY
                    guides.push({ axis: 'y', at: snap.y.at })
                  ractive.set('snapGuides', guides)
                moveGroupBy(starts, dx, dy)
              return

            # () => Unit
            onEnd: ->
              ractive.set('snapGuides', [])
              finishGroupMove(starts)
              return

          })
        return

    # (Context) => Unit
    beginBoxSelect =
      (event) ->
        domEvent  = event.original
        container = event.node
        if ractive.get('isEditing') and (domEvent.target is container)

          # ({ clientX: Number, clientY: Number }) => [Number, Number]
          toLocal =
            ({ clientX, clientY }) ->
              { left, top } = container.getBoundingClientRect()
              [clientX - left, clientY - top]

          [startX, startY] = toLocal(domEvent)
          keptWidgets      = []

          startPointerDrag(container, domEvent, {

            # (DragInfo) => Unit
            onStart: (info) ->
              ractive.fire('hide-context-menu')
              keptWidgets = if isTogglingSelection(info) then selection.all() else []
              return

            # (DragInfo) => Unit
            onMove: (info) ->
              [x, y] = toLocal(info)
              box    = rectFromCorners(startX, startY, x, y)
              ractive.set('selectionBox', box)
              touched = widgetComponents(ractive).filter( (c) -> rectsTouch(box, boundsOf(c)) )
              selection.replace(keptWidgets.concat(touched))
              return

            # () => Unit
            onEnd: ->
              ractive.set('selectionBox', null)
              return

          })
        return

    # () => Unit
    selectAllWidgets =
      ->
        if ractive.get('isEditing')
          selection.replace(widgetComponents(ractive))
        return

    isSelectingByPointer = false

    # (Context, PointerEvent) => Unit
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

    # (Context, MouseEvent | FocusEvent) => Unit
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

    # (Context | undefined, MouseEvent | undefined) => Unit
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

    # () => Boolean
    hideResizer =
      ->
        if ractive.get("isEditing")
          ractive.set('isResizerVisible', not ractive.get('isResizerVisible'))
          false
        else
          true

    # (Context, "up" | "down" | "left" | "right", Boolean | undefined) => Boolean
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

import startPointerDrag from "../pointer-drag.js"

import { findSnap, edgesOf }            from "../edge-snapping.js"
import { widgetComponents, boundsOf }  from "../widget-bounds.js"

RactiveResizer = Ractive.extend({

  _xAdjustment: undefined # Number
  _yAdjustment: undefined # Number
  _snapEdges:   undefined # Edges

  data: -> {
    isEnabled: false # Boolean
  , isVisible: true  # Boolean
  , target:    null  # Ractive
  }

  computed: {
    dims: ->
      """
      position: absolute;
      left: #{@get('x')}px; top: #{@get('y')}px;
      width: #{@get('width')}px; height: #{@get('height')}px;
      """
    midX:   -> (@get('width' ) / 2) - 5
    midY:   -> (@get('height') / 2) - 5
    x:      -> @get('target').get('x') - 5
    y:      -> @get('target').get('y') - 5
    height: -> @get('target').get('height') + 10
    width:  -> @get('target').get('width' ) + 10
  }

  # (Ractive | null) => Unit
  showFor: (component) ->
    @set('target', component ? null)
    return

  # (String, DragInfo) => Unit
  _resizeTo: (direction, { clientX, clientY, ctrlKey, metaKey }) ->

    isMac      = window.navigator.platform.startsWith('Mac')
    isSnapping = ((not isMac and not ctrlKey) or (isMac and not metaKey))
    xCoord     = clientX - @_xAdjustment
    yCoord     = clientY - @_yAdjustment

    target    = @get('target')
    oldLeft   = target.get('x')
    oldTop    = target.get('y')
    oldRight  = oldLeft + target.get('width')
    oldBottom = oldTop  + target.get('height')

    left   = ['left'  , xCoord]
    right  = ['right' , xCoord]
    top    = ['top'   , yCoord]
    bottom = ['bottom', yCoord]

    adjusters =
      switch direction
        when "Bottom"     then [bottom]
        when "BottomLeft" then [bottom, left]
        when "BottomRight"then [bottom, right]
        when "Left"       then [left]
        when "Right"      then [right]
        when "Top"        then [top]
        when "TopLeft"    then [top, left]
        when "TopRight"   then [top, right]
        else throw new Error("What the heck resize direction is '#{direction}'?")

    isXDir = (dir) -> (dir is 'left') or (dir is 'right')

    snap =
      if isSnapping
        moving = {
          xs: adjusters.filter(([dir]) ->     isXDir(dir)).map(([_, coord]) -> coord)
        , ys: adjusters.filter(([dir]) -> not isXDir(dir)).map(([_, coord]) -> coord)
        }
        findSnap(moving, @_snapEdges)
      else
        { x: null, y: null }

    axisSnap = (dir) -> if isXDir(dir) then snap.x else snap.y

    snapCoord =
      (dir, coord) ->
        if not isSnapping
          coord
        else if axisSnap(dir)?
          axisSnap(dir).at
        else
          Math.round(coord / 10) * 10

    oldCoords = { left: oldLeft, top: oldTop, bottom: oldBottom, right: oldRight }

    clamp = (dir, value) =>

      opposite =
        switch dir
          when 'left'   then 'right'
          when 'right'  then 'left'
          when 'top'    then 'bottom'
          when 'bottom' then 'top'
          else throw new Error("What the heck opposite direction is '#{dir}'?")

      oppositeValue = oldCoords[opposite]

      newValue = switch opposite
        when 'left'   then Math.max(value, oppositeValue + target.minWidth )
        when 'top'    then Math.max(value, oppositeValue + target.minHeight)
        when 'right'  then Math.min(value, oppositeValue - target.minWidth )
        when 'bottom' then Math.min(value, oppositeValue - target.minHeight)
        else throw new Error("No, really, what the heck opposite direction is '#{opposite}'?")

      Math.round(newValue)

    dirCoordPairs = adjusters.map(([dir, currentCor]) -> [dir, clamp(dir, snapCoord(dir, currentCor))])

    newChanges =
      if dirCoordPairs.every(([dir, coord]) -> not (((dir is 'left') or (dir is 'top')) and (coord < 0)))
        dirCoordPairs.reduce(((acc, [dir, coord]) -> acc[dir] = coord; acc), {})
      else
        {}

    newCoords = Object.assign({}, oldCoords, newChanges)

    finalCoords = {
      x:      newCoords.left,
      y:      newCoords.top,
      height: newCoords.bottom - newCoords.top,
      width:  newCoords.right  - newCoords.left
    }
    target.handleResize(finalCoords)

    guides =
      adjusters.filter(([dir]) -> axisSnap(dir)? and (newCoords[dir] is axisSnap(dir).at))
               .map(([dir]) -> { axis: (if isXDir(dir) then 'x' else 'y'), at: axisSnap(dir).at })
    @root.set('snapGuides', guides)

    return

  on: {

    'start-handle-drag': ({ node, original }) ->

      direction = node.dataset.direction

      startPointerDrag(node, original, {

        onStart: =>
          @fire('hide-context-menu')
          { left, top } = @find('.widget-resizer').getBoundingClientRect()
          @_xAdjustment = left - @get('x')
          @_yAdjustment = top  - @get('y')
          target        = @get('target')
          @_snapEdges   = edgesOf(widgetComponents(@root).filter( (c) -> c isnt target ).map(boundsOf))
          return

        onMove: (info) =>
          @_resizeTo(direction, info)
          return

        onEnd: =>
          @_xAdjustment = undefined
          @_yAdjustment = undefined
          @_snapEdges   = undefined
          @root.set('snapGuides', [])
          @get('target').handleResizeEnd()
          return

      })

      return

  }


  # coffeelint: disable=max_line_length
  template:
    """
    {{# isEnabled && isVisible && target !== null }}
    <div class="widget-resizer" style="{{dims}}">
      {{ #target.get("resizeDirs").includes("bottom")      }}<div on-pointerdown="start-handle-drag" class="widget-resize-handle" data-direction="Bottom"      style="cursor:  s-resize; bottom:          0; left: {{midX}}px;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("bottomLeft")  }}<div on-pointerdown="start-handle-drag" class="widget-resize-handle" data-direction="BottomLeft"  style="cursor: sw-resize; bottom:          0; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("bottomRight") }}<div on-pointerdown="start-handle-drag" class="widget-resize-handle" data-direction="BottomRight" style="cursor: se-resize; bottom:          0; right:         0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("left")        }}<div on-pointerdown="start-handle-drag" class="widget-resize-handle" data-direction="Left"        style="cursor:  w-resize; bottom: {{midY}}px; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("right")       }}<div on-pointerdown="start-handle-drag" class="widget-resize-handle" data-direction="Right"       style="cursor:  e-resize; bottom: {{midY}}px; right:         0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("top")         }}<div on-pointerdown="start-handle-drag" class="widget-resize-handle" data-direction="Top"         style="cursor:  n-resize; top:             0; left: {{midX}}px;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("topLeft")     }}<div on-pointerdown="start-handle-drag" class="widget-resize-handle" data-direction="TopLeft"     style="cursor: nw-resize; top:             0; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("topRight")    }}<div on-pointerdown="start-handle-drag" class="widget-resize-handle" data-direction="TopRight"    style="cursor: ne-resize; top:             0; right:         0;"></div>{{/}}
    </div>
    {{/}}
    """
  # coffeelint: enable=max_line_length

})

export default RactiveResizer

window.RactiveResizer = Ractive.extend({

  isLocked:     false     # Boolean
  lastUpdateMs: undefined # Number
  lastX:        undefined # Number
  lastY:        undefined # Number
  view:         undefined # Element

  data: -> {
    isEnabled: false # Boolean
  , target:    null  # Ractive
  }

  computed: {
    dims: ->
      """
      position: absolute;
      left: #{@get('left')}px; top: #{@get('top')}px;
      width: #{@get('width')}px; height: #{@get('height')}px;
      """
    midX:   -> (@get( 'width') / 2) - 5
    midY:   -> (@get('height') / 2) - 5
    left:   -> @get('target').get(  'left') - 5
    right:  -> @get('target').get( 'right') + 5
    top:    -> @get('target').get(   'top') - 5
    bottom: -> @get('target').get('bottom') + 5
    height: -> @get('bottom') - @get( 'top')
    width:  -> @get( 'right') - @get('left')
  }

  # () => Unit
  clearTarget: ->
    target = @get('target')
    if not @isLocked and target?
      if not target.destroyed
        target.find('.netlogo-widget').classList.remove('widget-selected')
      @set('target', null)
    return

  # (Element) => Unit
  setTarget: (newTarget) ->
    if not @isLocked
      setTimeout((=> # Use `setTimeout`, so any pending `clearTarget` resolves first --JAB (12/6/17)
        @clearTarget()
        @set('target', newTarget)
        newTarget.find('.netlogo-widget').classList.add('widget-selected')
      ), 0)
    return

  # (Element) => Unit
  lockTarget: (newTarget) ->
    if not @isLocked and newTarget?
      @setTarget(newTarget)
      @isLocked = true
    return

  # () => Unit
  unlockTarget: ->
    @isLocked = false
    return

  on: {

    'start-handle-drag': (event) ->
      CommonDrag.dragstart.call(this, event, (-> true), (x, y) =>
        @lastX = x
        @lastY = y
      )

    'drag-handle': (event) ->
      CommonDrag.drag.call(this, event, (x, y) =>

        target    = @get('target')
        oldLeft   = target.get('left')
        oldRight  = target.get('right')
        oldTop    = target.get('top')
        oldBottom = target.get('bottom')

        left   = ['left'  , @lastX, x]
        right  = ['right' , @lastX, x]
        top    = ['top'   , @lastY, y]
        bottom = ['bottom', @lastY, y]

        direction = event.original.target.dataset.direction

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

        exceedsOpposite = (dir, value) =>
          opposite =
            switch dir
              when 'left'   then 'right'
              when 'right'  then 'left'
              when 'top'    then 'bottom'
              when 'bottom' then 'top'
              else throw new Error("What the heck opposite direction is '#{dir}'?")
          oppositeValue = @get(opposite)
          ((opposite is 'left'  or opposite is 'top'   ) and newValue <= (oppositeValue + 26)) or
          ((opposite is 'right' or opposite is 'bottom') and newValue >= (oppositeValue - 26))

        findAdjustment = (n) -> n - (Math.round(n / 10) * 10)

        for [dir, lastCor, currentCor] in adjusters
          newValue   = target.get(dir) - (lastCor - currentCor)
          adjustment = findAdjustment(newValue)
          adjusted   = newValue - adjustment
          if not exceedsOpposite(dir, adjusted)
            target.set(dir, adjusted)

        @lastX = x
        @lastY = y

        @get('target').fire('widget-resized'
                           , oldLeft           , oldRight           , oldTop           , oldBottom
                           , target.get('left'), target.get('right'), target.get('top'), target.get('bottom')
                           )

      )

    'stop-handle-drag': ->
      CommonDrag.dragend.call(this, =>
        @lastX = undefined
        @lastY = undefined
      )

  }


  # coffeelint: disable=max_line_length
  template:
    """
    {{# isEnabled && target !== null }}
    <div class="widget-resizer" style="{{dims}}">
      {{ #target.get("resizeDirs").includes("bottom")      }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="Bottom"      style="cursor:  s-resize; bottom:          0; left:   {{midX}};"></div>{{/}}
      {{ #target.get("resizeDirs").includes("bottomLeft")  }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="BottomLeft"  style="cursor: sw-resize; bottom:          0; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("bottomRight") }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="BottomRight" style="cursor: se-resize; bottom:          0; right:         0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("left")        }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="Left"        style="cursor:  w-resize; bottom:   {{midY}}; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("right")       }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="Right"       style="cursor:  e-resize; bottom:   {{midY}}; right:         0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("top")         }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="Top"         style="cursor:  n-resize; top:             0; left:   {{midX}};"></div>{{/}}
      {{ #target.get("resizeDirs").includes("topLeft")     }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="TopLeft"     style="cursor: nw-resize; top:             0; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("topRight")    }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="TopRight"    style="cursor: ne-resize; top:             0; right:         0;"></div>{{/}}
    </div>
    {{/}}
    """
  # coffeelint: enable=max_line_length

})

window.RactiveResizer = Ractive.extend({

  lastX: undefined # Number
  lastY: undefined # Number
  view:  undefined # Element

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
    @get('target')?.find('.netlogo-widget').classList.remove('widget-selected')
    @set('target', null)
    return

  # (Element) => Unit
  setTarget: (newTarget) ->
    @clearTarget()
    @set('target', newTarget)
    newTarget.find('.netlogo-widget').classList.add('widget-selected')
    return

  on: {

    startHandleDrag: ({ original: { clientX, clientY, dataTransfer, view } }) ->

      invisiGIF = document.createElement('img')
      invisiGIF.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
      dataTransfer.setDragImage(invisiGIF, 0, 0)

      @view         = view
      @lastX        = clientX
      @lastY        = clientY
      @lastUpdateMs = (new Date).getTime()

      return

    stopHandleDrag: ->
      if @view?
        @view         = undefined
        @lastX        = undefined
        @lastY        = undefined
        @lastUpdateMs = undefined
      return

    dragHandle: ({ original: { clientX, clientY, target: { dataset: { direction } }, view } }) ->

      if @view?

        # When dragging stops, `client(X|Y)` tend to be very negative nonsense values
        # We only take non-negative values here, to avoid the widget disappearing --JAB (3/22/16, 10/29/17)

        # Only update drag coords 30 times per second.  If we don't throttle,
        # all of this `set`ing murders the CPU --JAB (10/29/17)
        if @view is view and clientX > 0 and clientY > 0 and ((new Date).getTime() - @lastUpdateMs) >= (1000 / 30)

          target    = @get('target')
          oldLeft   = target.get('left')
          oldRight  = target.get('right')
          oldTop    = target.get('top')
          oldBottom = target.get('bottom')

          left   = ['left'  , @lastX, clientX]
          right  = ['right' , @lastX, clientX]
          top    = ['top'   , @lastY, clientY]
          bottom = ['bottom', @lastY, clientY]

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

          for [dir, lastCor, currentCor] in adjusters
            newValue = target.get(dir) - (lastCor - currentCor)
            if not exceedsOpposite(dir, newValue)
              target.set(dir, newValue)

          @lastX = clientX
          @lastY = clientY

          @lastUpdateMs = (new Date).getTime()

          @get('target').fire('widget-resized'
                             , oldLeft           , oldRight           , oldTop           , oldBottom
                             , target.get('left'), target.get('right'), target.get('top'), target.get('bottom')
                             )

      false

  }


  # coffeelint: disable=max_line_length
  template:
    """
    {{# isEnabled && target !== null }}
    <div class="widget-resizer" style="{{dims}}">
      {{ #target.get("resizeDirs").includes("bottom")      }}<div draggable="true" on-drag="dragHandle" on-dragstart="startHandleDrag" on-dragend="stopHandleDrag" class="widget-resize-handle" data-direction="Bottom"      style="cursor:  s-resize; bottom:          0; left:   {{midX}};"></div>{{/}}
      {{ #target.get("resizeDirs").includes("bottomLeft")  }}<div draggable="true" on-drag="dragHandle" on-dragstart="startHandleDrag" on-dragend="stopHandleDrag" class="widget-resize-handle" data-direction="BottomLeft"  style="cursor: sw-resize; bottom:          0; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("bottomRight") }}<div draggable="true" on-drag="dragHandle" on-dragstart="startHandleDrag" on-dragend="stopHandleDrag" class="widget-resize-handle" data-direction="BottomRight" style="cursor: se-resize; bottom:          0; right:         0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("left")        }}<div draggable="true" on-drag="dragHandle" on-dragstart="startHandleDrag" on-dragend="stopHandleDrag" class="widget-resize-handle" data-direction="Left"        style="cursor:  w-resize; bottom:   {{midY}}; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("right")       }}<div draggable="true" on-drag="dragHandle" on-dragstart="startHandleDrag" on-dragend="stopHandleDrag" class="widget-resize-handle" data-direction="Right"       style="cursor:  e-resize; bottom:   {{midY}}; right:         0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("top")         }}<div draggable="true" on-drag="dragHandle" on-dragstart="startHandleDrag" on-dragend="stopHandleDrag" class="widget-resize-handle" data-direction="Top"         style="cursor:  n-resize; top:             0; left:   {{midX}};"></div>{{/}}
      {{ #target.get("resizeDirs").includes("topLeft")     }}<div draggable="true" on-drag="dragHandle" on-dragstart="startHandleDrag" on-dragend="stopHandleDrag" class="widget-resize-handle" data-direction="TopLeft"     style="cursor: nw-resize; top:             0; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("topRight")    }}<div draggable="true" on-drag="dragHandle" on-dragstart="startHandleDrag" on-dragend="stopHandleDrag" class="widget-resize-handle" data-direction="TopRight"    style="cursor: ne-resize; top:             0; right:         0;"></div>{{/}}
    </div>
    {{/}}
    """
  # coffeelint: enable=max_line_length

})

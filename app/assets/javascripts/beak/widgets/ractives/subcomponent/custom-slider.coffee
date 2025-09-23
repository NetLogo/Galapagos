RactiveCustomSlider = Ractive.extend({

  data: -> {
    value:         0               # Number
    min:           0               # Number
    max:           100             # Number
    step:          1               # Number
    snapTo:        undefined       # Number
    snapTolerance: undefined       # Number
    isEnabled:     true            # Boolean
    class:         null            # String
    onValueChange: null            # Function
    inputFor:      null            # String (id of an input element to update on change)
    maxDecimal:    2               # Number
    ariaLabel:     "Custom Slider" # String
    orientation:   "horizontal"    # String ("horizontal" or "vertical" (rotated 270 degrees))
  }

  computed: {
    percentFilled: ->
      min = @get("min")
      max = @get("max")
      val = @get("value")
      return 0 unless typeof val is 'number'
      Math.max(0, Math.min(1, (val - min) / (max - min))) * 100

    className: ->
      classes = ["netlogo-slider-bar", @get("class")]
      if @get("isEnabled") is false
        classes.push("disabled")
      return classes.filter(Boolean).join(" ")

    tabIndex: ->
      if @get("isEnabled") then 0 else -1
  }

  updateValue: (newValue) ->
    if typeof newValue is 'number'
      min = @get("min")
      max = @get("max")
      step = @get("step")

      newValue = Math.max(min, Math.min(max, newValue))
      newValue = Math.round(newValue / step) * step
      newValue = parseFloat(newValue.toFixed(@get("maxDecimal")))

      if newValue isnt @get("value")
        onChange = @get("onChange")
        if onChange?
          onChange(newValue)
        if @get("inputFor")?
          input = document.getElementById(@get("inputFor"))
          if input?
            input.value = newValue
            input.dispatchEvent(new Event("change", { bubbles: true }))

    return

  maybeSnapValue: () ->
    snapTo        = @get('snapTo')
    snapTolerance = @get('snapTolerance')
    if snapTo? and snapTolerance?
      min       = @get('min')
      max       = @get('max')
      range     = max - min
      snapSize  = range * snapTolerance / 100
      leftSnap  = snapTo - snapSize
      rightSnap = snapTo + snapSize
      value     = @get('value')
      if (value isnt snapTo) and (leftSnap < value) and (value < rightSnap)
        @set('value', value)
        @updateValue(snapTo)

    return

  getClientPosition: (event) ->
    switch @get('orientation')
      when 'horizontal' then event.clientX or event.touches?[0]?.clientX
      when 'vertical' then event.clientY or event.touches?[0]?.clientY
      else event.clientX or event.touches?[0]?.clientX

  getSliderLength: (node) ->
    rect = node.getBoundingClientRect()
    switch @get('orientation')
      when 'horizontal' then rect.width
      when 'vertical' then rect.height
      else throw new Error("Invalid orientation: #{@get('orientation')}")

  getSliderLengthFromNode: (node) ->
    # Might look like a typo, but since rotation happens using
    # CSS, the bounding box changes but the node's offsetWidth/Height
    # do not. -Omar I. Aug 14, 2025
    return node.offsetWidth

  getSliderStart: (node) ->
    rect = node.getBoundingClientRect()
    switch @get('orientation')
      when 'horizontal' then rect.left + window.scrollX
      when 'vertical' then rect.top + window.scrollY
      else throw new Error("Invalid orientation: #{@get('orientation')}")

  on: {
    'start-drag': (event) ->
      slider = this

      sliderLength = slider.getSliderLengthFromNode(event.node)
      min = slider.get("min")
      max = slider.get("max")
      step = slider.get("step")

      sliderStart = slider.getSliderStart(event.node)

      move = (e) ->
        currentPos = slider.getClientPosition(e)
        percent = (currentPos - sliderStart) / sliderLength
        if slider.get('orientation') is 'vertical'
          # The y-axis is inverted
          percent = 1 - percent
        percent = Math.max(0, Math.min(1, percent))
        val = min + percent * (max - min)
        val = Math.round(val / step) * step
        val = parseFloat(val.toFixed(slider.get("maxDecimal")))

        slider.updateValue(val)
        return

      stop = ->
        window.removeEventListener("mousemove", move)
        window.removeEventListener("mouseup", stop)
        window.removeEventListener("touchmove", move)
        window.removeEventListener("touchend", stop)
        slider.maybeSnapValue()
        return

      window.addEventListener("mousemove", move)
      window.addEventListener("mouseup", stop)
      window.addEventListener("touchmove", move)
      window.addEventListener("touchend", stop)
      move(event.original)
      event.original.preventDefault()

    'keydown': (event) ->
      if not @get("isEnabled")
        return

      allowedKeys = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"]
      if not (event.original.key in allowedKeys)
        return

      if document.activeElement is event.node
        event.original.preventDefault()

        val = @get("value")
        step = @get("step")
        if event.original.key is "ArrowLeft" or event.original.key is "ArrowDown"
          val -= step
        else if event.original.key is "ArrowRight" or event.original.key is "ArrowUp"
          val += step

        @updateValue(val)

      return

  }

  template: """
    <div class="{{className}}"
         on-mousedown="['start-drag']"
         on-touchstart="['start-drag']"
         on-keydown="['keydown']"
         role="slider"
         aria-valuemin="{{min}}"
         aria-valuemax="{{max}}"
         aria-valuenow="{{value}}"
         tabindex="{{tabIndex}}"
         aria-label="{{ariaLabel}}">
      <div class="netlogo-slider-bar-fill" style="width: {{percentFilled}}%;"></div>
      <div class="netlogo-slider-bar-handle" style="left: {{percentFilled}}%;"></div>
    </div>
  """

})

export default RactiveCustomSlider

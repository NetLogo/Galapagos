import Ractive from "ractive"

RactiveCustomSlider = Ractive.extend({

  data: -> {
    value: 0
    min: 0
    max: 100
    step: 1
    isEnabled: true
    class: null
    onValueChange: null
    inputFor: null
    maxDecimal: 2
    ariaLabel: "Custom Slider"
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

  on: {
    "start-drag": (event) ->
      slider = this
      startX = event.original.clientX or event.original.touches?[0]?.clientX
      sliderWidth = event.node.offsetWidth
      min = slider.get("min")
      max = slider.get("max")
      step = slider.get("step")

      rect = event.node.getBoundingClientRect()
      sliderLeft = rect.left + window.scrollX

      updateValue = slider.updateValue.bind(slider)

      move = (e) ->
        currentX = e.clientX or e.touches?[0]?.clientX or e.event.clientX
        percent = (currentX - sliderLeft) / sliderWidth
        percent = Math.max(0, Math.min(1, percent))
        val = min + percent * (max - min)
        val = Math.round(val / step) * step
        val = parseFloat(val.toFixed(slider.get("maxDecimal")))

        updateValue(val)

      stop = ->
        window.removeEventListener("mousemove", move)
        window.removeEventListener("mouseup", stop)
        window.removeEventListener("touchmove", move)
        window.removeEventListener("touchend", stop)

      window.addEventListener("mousemove", move)
      window.addEventListener("mouseup", stop)
      window.addEventListener("touchmove", move)
      window.addEventListener("touchend", stop)
      move(event)
      event.original.preventDefault()
    
    "keydown": (event) ->
      if not @get("isEnabled")
        return
      if not (event.original.key is "ArrowLeft" or event.original.key is "ArrowRight")
        return

      if document.activeElement is event.node
        event.original.preventDefault()

        val = @get("value")
        step = @get("step")
        if event.original.key is "ArrowLeft"
          val -= step
        else if event.original.key is "ArrowRight"
          val += step

        @updateValue(val)

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

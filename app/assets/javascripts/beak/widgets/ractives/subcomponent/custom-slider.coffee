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
      return classes.filter(Boolean).join(" ") # Filter out any empty classes
  }
  
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

      onChange = slider.get("onChange")

      move = (e) ->
        currentX = e.clientX or e.touches?[0]?.clientX
        percent = (currentX - sliderLeft) / sliderWidth
        percent = Math.max(0, Math.min(1, percent))
        val = min + percent * (max - min)
        val = Math.round(val / step) * step
        val = parseFloat(val.toFixed(slider.get("maxDecimal"))) # Limit decimal places

        if onChange?
          onChange(val)
        
        if slider.get("inputFor")?
          input = document.getElementById(slider.get("inputFor"))
          if input?
            input.value = val
            input.dispatchEvent(new Event("change", { bubbles: true }))

      stop = ->
        window.removeEventListener("mousemove", move)
        window.removeEventListener("mouseup", stop)
        window.removeEventListener("touchmove", move)
        window.removeEventListener("touchend", stop)

      window.addEventListener("mousemove", move)
      window.addEventListener("mouseup", stop)
      window.addEventListener("touchmove", move)
      window.addEventListener("touchend", stop)
      event.original.preventDefault()
  }

  template: """
    <div class="{{className}}"
         on-mousedown="['start-drag']"
         on-touchstart="['start-drag']"
         role="slider"
         aria-valuemin="{{min}}"
         aria-valuemax="{{max}}"
         aria-valuenow="{{value}}"
         aria-label="Custom Slider">
      <div class="netlogo-slider-bar-fill" style="width: {{percentFilled}}%;"></div>
      <div class="netlogo-slider-bar-handle" style="left: {{percentFilled}}%;"></div>
    </div>
  """

})

export default RactiveCustomSlider

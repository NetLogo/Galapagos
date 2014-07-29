window.Widgets =
  widgets: []
  widgetUpdateFuncs: []
  sliderUpdateFuncs: []
  addTo: (session) ->
    for widget in @widgets
      widget(session)
  runUpdateFuncs: () ->
    func() for func in @widgetUpdateFuncs
    func() for func in @sliderUpdateFuncs   # Do slider updates separately because they may depend on other sliders FD 2/7/13
  setDimensions: (e, left, top, right, bottom) ->
    e.style.width = right - left
    e.style.height = bottom - top
    e.style.top = top
    e.style.left = left
  addButton: (display, left, top, right, bottom, code, forever) ->
    escapedDisplay = display.replace("'", "\\'")
    @widgets.push((session) =>
      button = session.container.querySelector("button[netlogo-display='#{escapedDisplay}']")
      if not button?
        button = document.createElement('button')
        button.setAttribute('netlogo-display', display) # setAttribute handles escaping
        button.style.position = "absolute"
        button.style.fontSize = "8pt"
        @setDimensions(button, left, top, right, bottom)
        session.container.appendChild(button)

      button.innerHTML = display +
        if forever then " (Off)" else ""
      if forever
        running = false
        button.addEventListener("click",(() ->
          running = !running
          button.innerHTML = display +
            if running then " (On)" else " (Off)"))
        @widgetUpdateFuncs.push((() -> if running then code()))
      else
        button.addEventListener("click", code)
    )
  addSlider: (display, left, top, right, bottom, setter, min, max, def, step) ->
    escapedDisplay = display.replace("'", "\\'")
    @widgets.push((session) =>
      inputs = session.container.querySelectorAll(
        "input[type=range][netlogo-display='#{escapedDisplay}'], "+
        "input[type=number][netlogo-display='#{escapedDisplay}']")
      if inputs.length == 0
        slider = document.createElement('div')
        slider.style.position = "absolute"
        slider.style.fontSize = "8pt"
        @setDimensions(slider, left, top, right, bottom)

        width = Math.max(min.toString().length, max.toString().length) + 2
        
        numberInput = document.createElement('input')
        numberInput.type = "number"
        numberInput.setAttribute('netlogo-display', display)
        numberInput.style.cssFloat = "right"
        numberInput.style.fontSize = "8pt"
        numberInput.style.width = width + "em"
        numberInput.style.padding = "0px"
        # Getting all the components to stay within the bounds of the slider
        # for both Chrome and Firefox at the same time was awful. This is the
        # best I could come up with.
        # BCH 7/16/2014
        numberInput.style.marginTop = "-3px"
        numberInput.style.borderWidth = "1px"
        numberInput.style.textAlign = "right"

        rangeInput = document.createElement('input')
        rangeInput.setAttribute('netlogo-display', display) # setAttribute handles escaping
        rangeInput.type = "range"
        rangeInput.style.width = "97%"
        rangeInput.style.padding = "0px"

        label = document.createElement('label')
        label.innerHTML = display

        slider.appendChild(rangeInput)
        label.appendChild(numberInput)
        slider.appendChild(label)
        session.container.appendChild(slider)

        inputs = [rangeInput, numberInput]

      update = (e) ->
        value = parseInt(e.target.value)
        if not isNaN(value)
          for input in inputs
            input.value = value
          setter(value)

      for input in inputs 
        if typeof(max) == 'function'
          @sliderUpdateFuncs.push((() -> input.max = max()))
        input.max = max

        if typeof(min) == 'function'
          @sliderUpdateFuncs.push((() -> input.min = min()))
        input.min = min

        if typeof(step) == 'function'
          @sliderUpdateFuncs.push((() -> input.step = step()))
        input.step = step

        input.value = def

        input.addEventListener("input", update)

    )

  addSwitch: (display, left, top, right, bottom, setter) ->
    escapedDisplay = display.replace("'", "\\'")
    @widgets.push((session) =>
      input = session.container.querySelector(
        "input[type='checkbox'][netlogo-display='#{escapedDisplay}']")

      if not input?
        swtch = document.createElement('div')
        swtch.style.position = "absolute"
        swtch.style.fontSize = "8pt"
        @setDimensions(swtch, left, top, right, bottom)

        input = document.createElement('input')
        input.setAttribute('netlogo-display', display) # setAttribute handles escaping
        input.type = "checkbox"
        input.style.cssFloat = "left"

        label = document.createElement('label')
        label.innerHTML = display

        swtch.appendChild(input)
        swtch.appendChild(label)
        session.container.appendChild(swtch)

      input.onchange = () ->
        setter(input.checked)
    )

  addChooser: (display, left, top, right, bottom, defaultValue, choices, setter) ->
    escapedDisplay = display.replace("'", "\\'")
    @widgets.push((session) =>
      chooser = session.container.querySelector("div[netlogo-display='#{escapedDisplay}']")

      if not input?
        chooser = document.createElement('div')
        chooser.style.position = 'absolute'
        chooser.style.fontSize = '8pt'
        @setDimensions(chooser, left, top, right, bottom)

        label = document.createElement('label')
        label.innerHTML = display
        
        select = document.createElement('select')
        for choice in choices
          choiceElem = document.createElement('option')
          choiceElem.value = choice
          choiceElem.innerHTML = choice
          select.appendChild(choiceElem)
        select.value = defaultValue

        chooser.appendChild(label)
        chooser.appendChild(document.createElement('br'))
        chooser.appendChild(select)
        session.container.appendChild(chooser)

      select = chooser.querySelector('select')
      select.addEventListener('change', () -> setter(select.value))
    )

  addMonitor: (display, left, top, right, bottom, code) ->
    escapedDisplay = display.replace("'", "\\'")
    @widgets.push((session) =>
      value = session.container.querySelector("div[netlogo-display='#{escapedDisplay}']")
      if not value?
        monitor = document.createElement('div')
        monitor.style.position = "absolute"
        monitor.style.fontSize = "8pt"
        monitor.style.backgroundColor = "#CCCCCC"
        @setDimensions(monitor, left, top, right, bottom)

        heading = document.createElement('label')
        heading.style.margin = 4
        heading.innerHTML = display
        heading.style.position = "relative"

        value = document.createElement('div')
        value.setAttribute('netlogo-display', display) # setAttribute handles escaping
        value.style.backgroundColor = "white"
        value.style.position = "relative"
        value.style.margin = 4
        value.style.padding = 2

        monitor.appendChild(heading)
        monitor.appendChild(value)
        session.container.appendChild(monitor)

      value.innerHTML = "0"
      @widgetUpdateFuncs.push(() ->
        try
          result = code()
        catch e
          if e instanceof NetLogoException
            result  = "N/A"
          else
            throw e
        value.innerHTML = result
      )
    )
  addTextBox: (display, left, top, right, bottom) ->
    escapedDisplay = display.replace("'", "\\'")
    @widgets.push((session) =>
      textBox = session.container.querySelector("div[netlogo-display='#{escapedDisplay}']")
      if not textBox?
        textBox = document.createElement('div')
        textBox.setAttribute('netlogo-display', display) # setAttribute handles escaping
        textBox.style.position = "absolute"
        textBox.style.fontSize = "8pt"
        textBox.style.border = "2px solid black"
        textBox.style.textAlign = "center"
        @setDimensions(textBox, left + 2, top + 2, right - 2, bottom - 2)
        textBox.innerHTML = display
        session.container.appendChild(textBox)
    )
    #alert("Output")
  addOutput: (display, left, top, right, bottom) ->
    #alert("Output")
  addView: (left, top, right, bottom) ->
    @widgets.push((session) =>
      @setDimensions(session.controller.layers, left, top, right, bottom)
    )
  addPlot: (display, left, top, right, bottom, ymin, ymax, xmin, xmax) ->
    @widgets.push((session) =>
      if(session.plot)
        plot = document.createElement('div')
        plot.style.position = "absolute"
        plot.style.border = "1px solid black"
        @setDimensions(plot, left, top, right, bottom)
        session.container.appendChild(plot)
        session.plot.boot(display, ymin, ymax, xmin, xmax, plot)
    )

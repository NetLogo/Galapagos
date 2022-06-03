import loadHNWModel from "./load-model.js"

# ((String, Object[Any]) => Unit) => (String, Any) => Unit
sendHNWData = (send) -> (type, message) ->
  send(type, { data: message })
  return

# ((String, Object[Any]) => Unit) => (String, Any) => Unit
sendHNWWidgetMessage = (send) -> (type, message) ->
  send("hnw-widget-message", { data: { type, message } })
  return

# ( () => Session, (Session) => Unit, (String) => Unit, (String) => Unit
# , (String) => Unit, (String, Object[Any]) => Unit) => (Object[Any]) => Unit
loadInterface = ( getSession, setSession, setToken, setRole
                , setUsername, sendPayload) -> (data) ->

  setToken(data.token)
  setRole(data.role)
  setUsername(data.username)

  loadHNWModel(setSession)(data.role, data.view)

  session = getSession()
  ractive = session.widgetController.ractive

  sendWidget = sendHNWWidgetMessage(sendPayload)

  ractive.on("hnw-send-to-host", (_, type, message) ->
    sendHNWData(sendPayload)(type, message)
  )

  ractive.on("hnw-send-widget-message", (_, type, message) ->
    sendWidget(type, message)
  )

  for widget in data.role.widgets
    switch widget.type
      when "hnwInputBox"
        world.observer.setGlobal(widget.variable, widget.boxedValue.value)
      when "hnwSlider"
        world.observer.setGlobal(widget.variable, widget.default)
      when "hnwChooser"
        world.observer.setGlobal(widget.variable, widget.choices[widget.currentChoice])
      when "hnwSwitch"
        world.observer.setGlobal(widget.variable, widget.on)
      when "hnwView"
        session.widgetController.viewController.setTargetDims(widget)

  exiles =
    [ document.querySelector('.netlogo-header')
    , document.querySelector('.netlogo-display-horizontal')
    , document.querySelector('.netlogo-speed-slider')
    , document.querySelector('.netlogo-tab-area')
    ]

  exiles.forEach((n) -> n.style.display = "none")

  vc = session.widgetController.viewController

  onMouseDown =
    ->
      obj = { subtype: "mouse-down", xcor: vc.mouseXcor(), ycor: vc.mouseYcor() }
      sendWidget('view', obj)

  onMouseUp =
    ->
      obj = { subtype: "mouse-up", xcor: vc.mouseXcor(), ycor: vc.mouseYcor() }
      sendWidget('view', obj)

  previousMouseMoveTime = 0

  onMouseMove =
    ->
      if data.role.onCursorMove?
        millisBetween = (1 / data.tickRate) * 1000
        now           = performance.now()
        if (now - previousMouseMoveTime) >= millisBetween
          previousMouseMoveTime = now
          obj = { subtype: "mouse-move", xcor: vc.mouseXcor(), ycor: vc.mouseYcor() }
          sendWidget('view', obj)

  vc.view.visibleCanvas.addEventListener('mousedown', onMouseDown)
  vc.view.visibleCanvas.addEventListener('mouseup'  , onMouseUp  )
  vc.view.visibleCanvas.addEventListener('mousemove', onMouseMove)

  if data.token isnt "invalid token"
    data.port.postMessage(true)

  return

export default loadInterface

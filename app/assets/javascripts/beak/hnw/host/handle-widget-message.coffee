import { runAmbiguous, runCommand } from "./run.js"

# ((String) => Client, (String) => Role, () => Session) => (MessageEvent) => Unit
handleWidgetMessage = (getClient, getRole, getSession) -> (e) ->

  token  = e.data.token
  client = getClient(token)

  updateWidgetCache = getSession().hnw.updateWidgetCache(token)

  if client?

    role = getRole(client.roleName)
    who  = client.who

    switch e.data.data.type

      when "button"
        procedure = (-> runCommand(e.data.data.message))
        if role.isSpectator
          try procedure()
          catch ex
            if not (ex instanceof Exception.HaltInterrupt)
              throw ex
        else
          world.turtleManager.getTurtle(who).ask(procedure, false)

      when "slider", "switch", "chooser", "inputBox"

        { varName, value } = e.data.data

        trueValue =
          if e.data.data.type is "chooser"
            index = value - 1
            if index isnt -1
              chooser =
                role.widgets.find(
                  (w) ->
                    w.type is "hnwChooser" and
                      w.variable.toLowerCase() is varName.toLowerCase()
                )
              chooser.choices[index]
            else
              0
          else
            value

        if role.isSpectator
          mangledName = "__hnw_#{role.name}_#{varName}"
          world.observer.setGlobal(mangledName, trueValue)
        else
          f = (-> SelfManager.self().setVariable(varName, trueValue))
          world.turtleManager.getTurtle(who).ask(f, false)

        updateWidgetCache(varName, trueValue)

      when "view"

        message = e.data.data.message

        switch message.subtype
          when "mouse-down"
            if role.onCursorClick?
              thunk = (-> runAmbiguous(role.onCursorClick, message.xcor, message.ycor))
              if role.isSpectator
                thunk()
              else
                world.turtleManager.getTurtle(who).ask(thunk, false)

          when "mouse-up"
            if role.onCursorRelease?
              thunk = (-> runAmbiguous(role.onCursorRelease, message.xcor, message.ycor))
              if role.isSpectator
                thunk()
              else
                world.turtleManager.getTurtle(who).ask(thunk, false)

          when "mouse-move"
            if role.onCursorMove?
              thunk = (-> runAmbiguous(role.onCursorMove, message.xcor, message.ycor))
              if role.isSpectator
                thunk()
              else
                world.turtleManager.getTurtle(who).ask(thunk, false)

          else
            console.warn("Unknown HNW View event subtype")

      else
        console.warn("Unknown HNW widget event type")

  else
    console.warn("Received widget message from disconnected client", token)

export default handleWidgetMessage

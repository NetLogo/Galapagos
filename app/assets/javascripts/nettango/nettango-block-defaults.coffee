createCommand = (overrides) ->
  command = {
    , action:      "command"               # String
    , type:        "nlogo:command"         # "nlogo:procedure" | "nlogo:command" | "nlogo:if" | "nlogo:ifelse" | "nlogo:ask"
    , format:      "command1"              # String
    , start:       false                   # Boolean
    , control:     false                   # Boolean
    , required:    false                   # Boolean
    , limit:       undefined               # Integer
    , blockColor:  '#9977aa'               # String (hex color)
    , textColor:   '#ffffff'               # String (hex color)
    , borderColor: '#000000'               # String (hex color)
    , fontWeight:  400                     # Number
    , fontSize:    12                      # Number
    , fontFace:    "'Poppins', sans-serif" # String
    , params:      []                      # Array[Parameter]
  }
  if overrides?
    Object.assign(command, overrides)
  command


copyBlock = (block) ->
  copy = Object.assign({ }, block)
  copy.params = []
  if block.params?.length > 0
    block.params.forEach((param) ->
      paramCopy = Object.assign({ }, param)
      copy.params.push(paramCopy)
    )
  return copy

getBlockDefault = (group, number) ->
  block = copyBlock(NetTangoBlockDefaults.blocks[group].items[number])
  return block

blocks = {
  basics: {
    , name: "Basics"
    , items: [
      {
        , action:      "procedure"             # String
        , type:        "nlogo:procedure"       # "nlogo:procedure" | "nlogo:command" | "nlogo:if" | "nlogo:ifelse" | "nlogo:ask"
        , format:      "to proc1"              # String
        , start:       true                    # Boolean
        , control:     false                   # Boolean
        , required:    true                    # Boolean
        , limit:       1                       # Integer
        , blockColor:  '#bb5555'               # String (hex color)
        , textColor:   '#ffffff'               # String (hex color)
        , borderColor: '#000000'               # String (hex color)
        , fontWeight:  400                     # Number
        , fontSize:    12                      # Number
        , fontFace:    "'Poppins', sans-serif" # String
        , params:      []                      # Array[Parameter]
      }
      , createCommand()
      , {
        , action:      "nested statement"      # String
        , type:        "nlogo:if"              # "nlogo:procedure" | "nlogo:command" | "nlogo:if" | "nlogo:ifelse" | "nlogo:ask"
        , format:      "if random 10 < 5"      # String
        , start:       false                   # Boolean
        , control:     true                    # Boolean
        , required:    false                   # Boolean
        , limit:       undefined               # Integer
        , blockColor:  '#8899aa'               # String (hex color)
        , textColor:   '#ffffff'               # String (hex color)
        , borderColor: '#000000'               # String (hex color)
        , fontWeight:  400                     # Number
        , fontSize:    12                      # Number
        , fontFace:    "'Poppins', sans-serif" # String
        , params:      []                      # Array[Parameter]
      }
    ]
  }
  , controlCommands: {
    , name: "Control Blocks"
    , items: [
      {
        , action:      "ask turtles"           # String
        , type:        "nlogo:ask"             # "nlogo:procedure" | "nlogo:command" | "nlogo:if" | "nlogo:ifelse" | "nlogo:ask"
        , format:      "ask turtles"           # String
        , start:       false                   # Boolean
        , control:     true                    # Boolean
        , required:    false                   # Boolean
        , limit:       undefined               # Integer
        , blockColor:  '#8899aa'               # String (hex color)
        , textColor:   '#ffffff'               # String (hex color)
        , borderColor: '#000000'               # String (hex color)
        , fontWeight:  400                     # Number
        , fontSize:    12                      # Number
        , fontFace:    "'Poppins', sans-serif" # String
        , params:      []                      # Array[Parameter]
      }
      , createCommand({
        , action:  "chance"
        , type:    "nlogo:if"
        , format:  "if random 100 < {0}"
        , control: true
        , blockColor: '#8899aa'
        , params: [ {
            type: "range",
            min:  0,
            max:  100,
            step: 0.5,
            def:  20,
            unit: "%",
            name: "percent"
        } ]
      })
    ]
  }
  , observerCommands: {
    , name: "Global Commands"
    , items: [
      createCommand({
        , action: "create turtles"
        , format: "crt {0} [ fd 1 ]"
        , params: [ {
            type: "range",
            min:  1,
            max:  100,
            step: 1,
            def:  10,
            name: "turtles"
          } ]
      })
    ]
  }
  , turtleCommands: {
    , name: "Turtle Commands"
    , items: [
      createCommand({
        , action: "forward"
        , format: "fd {0}"
        , params: [ {
            type: "range",
            min:  0,
            max:  3,
            step: 0.1,
            def:  1,
            name: "steps"
          } ]
      })
      , createCommand({
        , action: "wiggle"
        , format: "left (random {0} - ({0} / 2))"
        , params: [ {
            type:   "range",
            min:    0,
            max:    180,
            step:   3,
            def:    30,
            random: true,
            name:   "amount",
            unit:   "°"
        } ]
      })
      , createCommand({
        , action: "hatch"
        , format: "hatch 1 [ right random-float 360 fd 1 ]"
      })
      , createCommand({
        , action: "die"
        , format: "die"
      })
      , createCommand({
        , action: "change color"
        , format: "set color {0}"
        , params: [ {
            type: "range",
            min:  0,
            max:  155,
            step: 1,
            def:  50,
            name: "color",
            unit: ""
        } ]
      })
      , createCommand({
        , action: "random color"
        , format: "set color random {0}"
        , params: [ {
            type: "range",
            min:  0,
            max:  155,
            step: 1,
            def:  50,
            name: "color",
            unit: ""
        } ]
      })
    ]
  }
}

window.NetTangoBlockDefaults = { blocks, copyBlock, getBlockDefault }

copyBlock = (block) ->
  copy = Object.assign({ }, block)

  copyPThings = (b, pThings) ->
    if b[pThings]?
      b[pThings].map( (pThing) ->
        pThing['def'] = pThing['default']
        pCopy = Object.assign({ }, pThing)
        if pThing.type is 'select'
          pCopy.values = pThing.values.slice()
          pCopy.valuesString = pCopy.values.join(';')
        pCopy
      )
    else
      []

  copy.params     = copyPThings(block, 'params')
  copy.properties = copyPThings(block, 'properties')

  copy

createCommand = (overrides) ->
  command = {
    , action:      "command"
    , type:        "nlogo:command"
    , format:      "command1"
    , start:       false
    , control:     false
    , required:    false
    , limit:       undefined
    , blockColor:  '#9977aa'
    , textColor:   '#ffffff'
    , borderColor: '#000000'
    , fontWeight:  400
    , fontSize:    12
    , fontFace:    "'Poppins', sans-serif"
    , params:      []
    , properties:  []
  }
  if overrides?
    Object.assign(command, overrides)
  command

blocks = {
  name: 'nettango-block-defaults',
  items: [
    {
      name: "Basics"
      , items: [
        {
          name: 'command'
          data: createCommand()
        },
        {
          name: 'procedure'
          data: {
            , action:      "procedure"
            , type:        "nlogo:procedure"
            , format:      "to proc1"
            , start:       true
            , control:     false
            , required:    true
            , limit:       1
            , blockColor:  '#bb5555'
            , textColor:   '#ffffff'
            , borderColor: '#000000'
            , fontWeight:  400
            , fontSize:    12
            , fontFace:    "'Poppins', sans-serif"
            , params:      []
            , properties:  []
          }
        },
        {
          name: 'nested statement (if)',
          data: {
            , action:      "nested statement"
            , type:        "nlogo:if"
            , format:      "if random 10 < 5"
            , start:       false
            , control:     true
            , required:    false
            , limit:       undefined
            , blockColor:  '#8899aa'
            , textColor:   '#ffffff'
            , borderColor: '#000000'
            , fontWeight:  400
            , fontSize:    12
            , fontFace:    "'Poppins', sans-serif"
            , params:      []
            , properties:  []
          }
        },
        {
          name: 'nested statement (if-else)',
          data: {
            , action:      "nested statement"
            , type:        "nlogo:ifelse"
            , format:      "ifelse (random 10 < count turtles)"
            , start:       false
            , control:     true
            , required:    false
            , limit:       undefined
            , blockColor:  '#8899aa'
            , textColor:   '#ffffff'
            , borderColor: '#000000'
            , fontWeight:  400
            , fontSize:    12
            , fontFace:    "'Poppins', sans-serif"
            , params:      []
            , properties:  []
          }
        }
      ]
    },
    {
      name: "Control Blocks"
      , items: [
        {
          name: 'ask turtles',
          data: {
            , action:      "ask turtles"
            , type:        "nlogo:ask"
            , format:      "ask turtles"
            , start:       false
            , control:     true
            , required:    false
            , limit:       undefined
            , blockColor:  '#8899aa'
            , textColor:   '#ffffff'
            , borderColor: '#000000'
            , fontWeight:  400
            , fontSize:    12
            , fontFace:    "'Poppins', sans-serif"
            , params:      []
            , properties:  []
          }
        },
        {
          name: "chance",
          data: createCommand({
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
        },
        {
          name: "if",
          data: createCommand({
            , action:  "if"
            , type:    "nlogo:if"
            , format:  "if {0}"
            , control: true
            , blockColor: '#8899aa'
            , params: [ {
                type: "bool",
                def:  false,
                name: "case"
            } ]
          })
        }
      ]
    },
    {
      name: "Global Commands"
      , items: [
        {
          name: 'create turtles',
          data: createCommand({
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
        }
      ]
    },
    {
      name: "Turtle Commands"
      , items: [
        {
          name: "forward",
          data: createCommand({
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
        },
        {
          name: "wiggle",
          data: createCommand({
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
        },
        {
          name: "hatch",
          data: createCommand({
            , action: "hatch"
            , format: "hatch 1 [ right random-float 360 fd 1 ]"
          })
        },
        {
          name: "die",
          data: createCommand({
            , action: "die"
            , format: "die"
          })
        },
        {
          name: "change color",
          data: createCommand({
            , action: "change color"
            , format: "set color {0}"
            , params: [ {
              name: "color",
              unit: "",
              type: "select",
              default: "",
              values: [
                "red",
                "violet",
                "blue",
                "green",
                "yellow",
                "orange",
                "white",
                "black",
                "grey",
                "brown"
              ]
            } ]
          })
        },
        {
          name: "random color",
          data: createCommand({
            , action: "random color"
            , format: "set color random {0}"
            , properties: [ {
                type: "range",
                min:  0,
                max:  155,
                step: 1,
                def:  50,
                name: "color",
                unit: ""
            } ]
          })
        }
      ]
    }
  ]
}

window.NetTangoBlockDefaults = { blocks, copyBlock }

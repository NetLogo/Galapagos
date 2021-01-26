copyClauses = (block) ->
  if not block.clauses?
    return []

  block.clauses.map( (clause) ->
    copy             = Object.assign({}, clause)
    copy.allowedTags = copyAllowedTags(copy)
    copy
  )

# (NetTangoBlock, String) => Array[NetTangoAttribute]
copyAttributes = (b, attributeType) ->
  if b[attributeType]?
    b[attributeType].map( (attribute) ->
      attribute['def'] = attribute['default']
      attrCopy = Object.assign({}, attribute)
      if attribute.type is 'select'
        attrCopy.values = attribute.values.slice()
      attrCopy
    )
  else
    []

# ({ allowedTags: NetTangoAllowedTags }) => NetTangoAllowedTags
copyAllowedTags = (o) ->
  if o['allowedTags']?
    allowedTags = {
      type: o.allowedTags.type
    }

    if allowedTags.type is 'any-of' and o.allowedTags['tags']?
      allowedTags.tags = o.allowedTags.tags.slice()

    allowedTags

  else
    undefined

# (NetTangoBlock) => NetTangoBlock
copyBlock = (block) ->
  copy = Object.assign({}, block)
  delete copy.id
  copy.clauses     = copyClauses(block)
  copy.params      = copyAttributes(block, 'params')
  copy.properties  = copyAttributes(block, 'properties')
  copy.allowedTags = copyAllowedTags(block)
  copy.tags        = if block.tags? then block.tags.slice() else undefined
  copy

# (NetTangoBlock) => NetTangoBlock
createCommand = (overrides) ->
  command = {
    , action:     "command"
    , format:     "command1"
    , required:   false
    , placement:  NetTango.blockPlacementOptions.CHILD
    , limit:      undefined
    , params:     []
    , properties: []
  }
  if overrides?
    Object.assign(command, overrides)
  command

blocks = {
  name: "nettango-block-defaults",
  items: [
    {
      name: "Basics"
      , items: [
        {
          name: "empty command"
          data: createCommand()
        },
        {
          name: "new procedure"
          data: {
            , action:     "procedure"
            , format:     "to proc1"
            , required:   true
            , placement:  NetTango.blockPlacementOptions.STARTER
            , limit:      1
            , params:     []
            , properties: []
          }
        },
        {
          name: "wrapping procedure"
          data: {
            , action:     "procedure"
            , format:     "to proc1"
            , required:   true
            , isTerminal: true
            , placement:  NetTango.blockPlacementOptions.STARTER
            , limit:      1
            , clauses:    [{ children: [], open: " ", close: " " }]
          }
        }
      ]
    },
    {
      name: "Control Blocks"
      , items: [
        {
          name: "ask turtles",
          data: {
            , action:      "ask turtles"
            , format:      "ask turtles"
            , required:    false
            , limit:       undefined
            , params:      []
            , properties:  []
            , clauses:     [{ children: [] }]
          }
        },
        {
          name: "chance",
          data: createCommand({
            , action:  "chance"
            , format:  "if random 100 < {0}"
            , params: [ {
                type: "range",
                min:     0,
                max:     100,
                step:    0.5,
                default: 20,
                unit:    "%",
                name:    "percent"
            } ]
            , clauses: [{ children: [] }]
          })
        },
        {
          name: "if",
          data: {
            , action:      "if"
            , format:      "if random 10 < 5"
            , required:    false
            , limit:       undefined
            , params:      []
            , properties:  []
            , clauses:     [{ children: [] }]
          }
        },
        {
          name: "ifelse",
          data: {
            , action:      "ifelse"
            , format:      "ifelse (random 10 < count turtles)"
            , required:    false
            , limit:       undefined
            , params:      []
            , properties:  []
            , clauses:     [{ children: [] }, { children: [] }]
          }
        },
        {
          name: "ifelse-else (3 clause)"
          data: {
            action:       "ifelse-else (3 clause)",
            required:     false,
            format:       "(ifelse",
            closeClauses: ")"
            clauses: [
              { children: [], open: "random 10 < 5 [" },
              { children: [], action: "else maybe", open: "random 10 < 5 [" },
              { children: [], action: "otherwise" }
            ]
          }
        }
      ]
    },
    {
      name: "Global Commands"
      , items: [
        {
          name: "create turtles",
          data: createCommand({
            , action: "create turtles"
            , format: "crt {0} [ fd 1 ]"
            , params: [ {
                type:    "range",
                min:     1,
                max:     100,
                step:    1,
                default: 10,
                name:    "turtles"
              } ]
            , clauses: []
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
                type:    "range",
                min:     0,
                max:     3,
                step:    0.1,
                default: 1,
                name:    "steps"
              } ]
          })
        },
        {
          name: "wiggle",
          data: createCommand({
            , action: "wiggle"
            , format: "left (random {0} - ({0} / 2))"
            , params: [ {
                type:    "range",
                min:     0,
                max:     180,
                step:    3,
                default: 30,
                random:  true,
                name:    "amount",
                unit:    "°"
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
              default: "red",
              quoteValues: NetTango.selectQuoteOptions.NEVER_QUOTE,
              values: [
                { actual: "red" },
                { actual: "violet" },
                { actual: "blue" },
                { actual: "green" },
                { actual: "yellow" },
                { actual: "orange" },
                { actual: "white" },
                { actual: "black" },
                { actual: "grey" },
                { actual: "brown" }
              ]
            } ]
          })
        },
        {
          name: "random color",
          data: createCommand({
            , action: "random color"
            , format: "set color random {P0}"
            , properties: [ {
                type:    "range",
                min:     0,
                max:     155,
                step:    1,
                default: 50,
                name:    "color",
                unit:    ""
            } ]
          })
        }
      ]
    }
  ]
}

expressions = [
  { name: "true",  type: "bool" },
  { name: "false", type: "bool" },
  { name: "AND",   type: "bool", arguments: [ "bool", "bool"],  format: "({0} and {1})" },
  { name: "OR",    type: "bool", arguments: [ "bool", "bool" ], format: "({0} or {1})" },
  { name: "NOT",   type: "bool", arguments: [ "bool"],          format: "(not {0})" },
  { name: ">",     type: "bool", arguments: [ "num", "num" ] },
  { name: ">=",    type: "bool", arguments: [ "num", "num" ] },
  { name: "<",     type: "bool", arguments: [ "num", "num" ] },
  { name: "<=",    type: "bool", arguments: [ "num", "num" ] },
  { name: "!=",    type: "bool", arguments: [ "num", "num" ] },
  { name: "=",     type: "bool", arguments: [ "num", "num" ] },
  { name: "+",     type: "num",  arguments: [ "num", "num"] },
  { name: "-",     type: "num",  arguments: [ "num", "num"] },
  { name: "×",     type: "num",  arguments: [ "num", "num"], format: "({0} * {1})" },
  { name: "/",     type: "num",  arguments: [ "num", "num"] },
  { name: "random", type: "num", arguments: [ "num" ], format: "random-float {0}" }
]

window.NetTangoBlockDefaults = { blocks, copyBlock, expressions }

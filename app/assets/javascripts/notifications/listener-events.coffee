# The function values in the map take custom event args corresponding to their event type (see the definitions below).
# type Listener = Map[String, (CommonArgs, EventTypeArgs) => Unit]

# type ListenerEvent = {
#   name: String
#   args: Array[String | DependentArg]
# }

# DependentArg exists for widgets and compile errors at this point.  For widgets we want some way to have them share the
# basic `id` and `type`, but then differentiate the rest of their fields based on the `type`.  It's probably a bit
# over-engineered, but it's a small impact and it works so I'll leave it alone for now.  -Jeremy B December 2022

# type DependentArg = {
#   sourceArg: String
#   cases: Array[Dependency]
# }

# type Dependency = {
#   sourceArgValues: Array[String]
#   argToAdd: String
# }

# Array[ListenerEvent]
widgetArgs = Object.freeze([
  'id'    # Number
  'type', # 'button' | 'chooser' | 'inputBox' | 'textBox' | 'monitor' | 'output' | 'plot' | 'slider' | 'switch'
  {
    sourceArg: 'type'
    cases: [
      { sourceArgValues: ['chooser', 'inputBox', 'slider', 'switch'], argToAdd: 'global' }
    , { sourceArgValues: ['button', 'monitor', 'plot']              , argToAdd: 'name' }
    , { sourceArgValues: ['textBox']                                , argToAdd: 'text' }
    ]
  },
  {
    sourceArg: 'type'
    cases: [
      { sourceArgValues: ['button', 'monitor'], argToAdd: 'code' }
    ]
  }
])

# Array[ListenerEvent]
listenerEvents = Object.freeze([
  {
    'name': 'model-load',
    'args': [
      'source',  # 'file' | 'new-model' | 'url' | 'script-element'
      'location' # String
    ]
  },
  {
    'name': 'compile-start',
    'args': [
      'nlogo',        # String, possibly rewritten nlogo code for the compile
      'originalNlogo' # String, original nlogo code from the model load
    ]
  },
  {
    'name': 'compile-complete',
    'args': [
      'nlogo',         # String, possibly rewritten nlogo code for the compile
      'originalNlogo', # String, original nlogo code from the model load
      'status',        # Boolean
      {
        sourceArg: 'status'
        cases: [
          { sourceArgValues: ['failure'], argToAdd: 'failure-level' }
        ]
      }
    ]
  },
  {
    'name': 'startup-procedure-run',
    'args': []
  },
  {
    'name': 'session-loop-started',
    'args': []
  },
  {
    'name': 'recompile-start',
    'args': [
      'source',      # 'user' | 'system', only 'user' if the user clicked Recompile
      'code',        # String, the NetLogo code contents, possibly rewritten
      'originalCode' # String, the original NetLogo code
    ]
  },
  {
    'name': 'recompile-complete',
    'args': [
      'source',      # 'user' | 'system', only 'user' if the user clicked Recompile
      'code',        # String, the NetLogo code contents, possibly rewritten
      'originalCode' # String, the original NetLogo code
    ]
  },
  {
    'name': 'new-widget-initialized',
    'args': [
      'id'    # Number
      'type', # 'button' | 'chooser' | 'inputBox' | 'textBox' | 'monitor' | 'output' | 'plot' | 'slider' | 'switch'
    ]
  },
  {
    'name': 'new-widget-finalized',
    'args': widgetArgs
  },
  {
    'name': 'new-widget-cancelled',
    'args': [
      'id'    # Number
      'type', # 'button' | 'chooser' | 'inputBox' | 'textBox' | 'monitor' | 'output' | 'plot' | 'slider' | 'switch'
    ]
  },
  {
    'name': 'widget-updated',
    'args': widgetArgs
  },
  {
    'name': 'widget-deleted',
    'args': widgetArgs
  },
  {
    'name': 'widget-moved',
    'args': [
      'id',     # Number
      'type',   # 'button' | 'chooser' | 'inputBox' | 'textBox' | 'monitor' | 'output' | 'plot' | 'slider' | 'switch'
      'top',    # Number
      'bottom', # Number
      'left',   # Number
      'right'   # Number
    ]
  },
  {
    'name': 'info-updated',
    'args': [
      'text' # String, new contents of the info area
    ]
  },
  {
    'name': 'button-widget-clicked',
    'args': [
      'id',          # Number
      'name',        # String
      'code',        # String
      'isForever',   # Boolean
      'isNowRunning' # Boolean, false if not a forever button or a forever button was turned off
    ]
  },
  {
    'name': 'slider-widget-changed',
    'args': [
      'id',       # Number
      'global',   # String
      'newValue', # Number, the new value of the widget
      'oldValue'  # Number, the prior value of the widget
    ]
  },
  {
    'name': 'chooser-widget-changed',
    'args': [
      'id',       # Number
      'global',   # String
      'newValue', # Any, the new value of the widget
      'oldValue', # Any, the prior value of the widget
    ]
  },
  {
    'name': 'input-widget-changed',
    'args': [
      'id',       # Number
      'global',   # String
      'newValue', # Any, the new value of the widget
      'oldValue', # Any, the prior value of the widget
      'type'      # 'Number' | 'String' | 'String (reporter)' | 'String (command)' | 'Color'
    ]
  },
  {
    'name': 'switch-widget-changed',
    'args': [
      'id'        # Number
      'global',   # String
      'newValue', # Boolean, the new value of the widget
      'oldValue', # Boolean, the prior value of the widget
    ]
  },
  {
    'name': 'command-center-run',
    'args': [
      'command' # String
    ]
  },
  {
    'name': 'speed-slider-changed',
    'args': [
      'speed' # Number, the new speed from -1 (slowest) to 1 (fastest)
    ]
  },
  {
    'name': 'command-center-toggled',
    'args': [
      'isOpen' # Boolean
    ]
  },
  {
    'name': 'model-code-toggled',
    'args': [
      'isOpen' # Boolean
    ]
  },
  {
    'name': 'model-info-toggled',
    'args': [
      'isOpen' # Boolean
    ]
  },
  {
    'name': 'authoring-mode-toggled',
    'args': [
      'isActive' # Boolean
    ]
  },
  {
    'name': 'notify-user',
    'args': [
      'message' # String
    ]
  },
  {
    'name': 'compiler-error',
    'args': [
      'source', # 'recompile' | 'recompile-procedures' | 'export-nlogo' | 'export-html' | 'button' | 'chooser'
                # | 'slider' | 'plot' | 'input' | 'switch' | 'console'
      'errors'  # Array[Exception]
    ]
  },
  {
    'name': 'runtime-error',
    'args': [
      'source',   # 'button' | ' console'
      'exception' # Exception
    ]
  },
  {
    'name': 'extension-error',
    'args': [
      'messages' # Array[String]
    ]
  }
])

getArgName = (argSetting, args) ->
  if (typeof argSetting) is 'string'
    argSetting
  else
    dependentValue = args[argSetting.sourceArg]
    maybeCase = argSetting.cases.filter( (argCase) ->
      argCase.sourceArgValues.includes(dependentValue)
    )
    if maybeCase.length is 1
      foundCase = maybeCase[0]
      foundCase.argToAdd
    else
      null

# (Array[String | DependentArg], Array[Any]) => EventTypeArgs
createNamedArgs = (argSettings, argValues) ->
  namedArgs = {}
  if (argSettings.length < argValues.length)
    throw new Error("not enough arg settings for the values given")
  argSettings.forEach( (argSetting, i) ->
    argName = getArgName(argSetting, namedArgs)
    if argName isnt null
      namedArgs[argName] = argValues[i]
  )
  namedArgs

# () => CommonArgs
createCommonArgs = () ->
  {
    timeStamp: Date.now()
  }

# (Array[String], Array[Listener]) => (String, Array[Any]) => Unit
createNotifier = (events, listeners) ->
  eventsByName = events.reduce( (current, event) ->
    current.set(event.name, event)
    current
  , new Map()
  )

  (eventName, args...) ->
    eventListeners = listeners.filter( (l) -> l[eventName]? )
    if eventListeners.length > 0
      event      = eventsByName.get(eventName)
      commonArgs = createCommonArgs()
      eventArgs  = createNamedArgs(event.args, args)
      eventListeners.forEach( (l) ->
        l[eventName](commonArgs, eventArgs)
      )
    return

export { createCommonArgs, createNamedArgs, createNotifier, listenerEvents }

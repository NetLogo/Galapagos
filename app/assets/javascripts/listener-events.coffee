widgetArgs = Object.freeze([
  'id'    # Number
  'type', # 'button' | 'chooser' | 'inputBox' | 'textBox' | 'monitor' | 'output' | 'plot' | 'slider' | 'switch'
  {
    dependentArg: 'type'
    cases: [
      { name: 'global', dependentValues: ['chooser', 'inputBox', 'slider', 'switch'] }
    , { name: 'name',   dependentValues: ['button', 'monitor', 'plot'] }
    , { name: 'text',   dependentValues: ['textBox'] }
    ]
  },
  {
    dependentArg: 'type'
    cases: [
      { name: 'code', dependentValues: ['button', 'monitor'] }
    ]
  }
])

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
      'nlogo',        # String, possibly rewritten nlogo code for the compile
      'originalNlogo' # String, original nlogo code from the model load
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
    dependentValue = args[argSetting.dependentArg]
    maybeCase = argSetting.cases.filter( (argCase) ->
      argCase.dependentValues.includes(dependentValue)
    )
    if maybeCase.length is 1
      foundCase = maybeCase[0]
      foundCase.name
    else
      null

createNamedArgs = (argSettings, argValues) ->
  namedArgs = {}
  argSettings.forEach( (argSetting, i) ->
    argName = getArgName(argSetting, namedArgs)
    if argName isnt null
      namedArgs[argName] = argValues[i]
  )
  namedArgs

createCommonArgs = () ->
  {
    timeStamp: Date.now()
  }

createNotifier = (events, listeners) ->
  eventsByName = events.reduce( (current, event) ->
    current.set(event.name, event)
  , new Map()
  )

  (eventName, args...) ->
    event      = eventsByName.get(eventName)
    commonArgs = createCommonArgs()
    eventArgs  = createNamedArgs(event.args, args)
    listeners.forEach( (listener) ->
      if listener[event]?
        listener[event](commonArgs, eventArgs)
    )
    return

export { createCommonArgs, createNamedArgs, createNotifier, listenerEvents }

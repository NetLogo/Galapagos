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
    'name': 'model-load-failed',
    'args': [
      'source',   # 'url' | 'disk' | 'new' | 'script-element'
      'location', # String
      'errors',   # Array[String | Exception]
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
      'nlogo',           # String, possibly rewritten nlogo code for the compile
      'originalNlogo',   # String, original nlogo code from the model load
      'modelSourceType', # 'url' | 'disk' | 'new' | 'script-element'
      'status',          # 'success' | 'failure'
      {
        sourceArg: 'status'
        cases: [
          { sourceArgValues: ['failure'], argToAdd: 'failureLevel' } # 'compile-recoverable' | 'compile-fatal'
        , { sourceArgValues: ['failure'], argToAdd: 'errors' }       # Array[String | Exception]
        ]
      }
    ]
  },
  {
    'name': 'revert-work-in-progress',
    'args': []
  },
  {
    'name': 'undo-revert',
    'args': []
  },
  {
    'name': 'nlogo-exported',
    'args': [
      'fileName', # The fileName that was given to the export
      'nlogo'     # The nlogo source that was exported
    ]
  },
  {
    'name': 'html-exported',
    'args': [
      'fileName', # The fileName that was given to the export
      'nlogo'     # The nlogo source that was inserted into the HTML
    ]
  }
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
      'y',      # Number
      'height', # Number
      'x',      # Number
      'width'   # Number
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
    'name': 'title-changed',
    'args': [
      'title' # String
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
      # At the moment runtime errors from the engine are labelled as `button` errors, because that's how the engine code
      # typically gets run but this seems a little odd to me looking at it now.  I'd expect `button` errors to be
      # runtime errors from the code of the button itself before control is passed to a "code tab" procedure.  Not going
      # to change anything for now, just noting it for others. -Jeremy B March 2023
      'source',    # 'button' | 'console' | 'startup'
      'exception', # Exception
      'code'       # String | undefined - only provided for command console errors or errors within button code
    ]
  },
  {
    'name': 'extension-error',
    'args': [
      'messages' # Array[String]
    ]
  }
])

getArgNames = (argSetting, namedArgs) ->
  if (typeof argSetting) is 'string'
    [argSetting]
  else
    dependentValue = namedArgs[argSetting.sourceArg]
    cases = argSetting.cases.filter( (argCase) ->
      argCase.sourceArgValues.includes(dependentValue)
    )
    cases.map( (c) => c.argToAdd )

# (Array[String | DependentArg], Array[Any]) => EventTypeArgs
createNamedArgs = (argSettings, argValues) ->
  namedArgs = {}
  argSettings.forEach( (argSetting, i) ->
    argNames = getArgNames(argSetting, namedArgs)
    argNames.forEach( (argName, j) ->
      namedArgs[argName] = argValues[i + j]
    )
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

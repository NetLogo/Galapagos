import { RactiveCodeContainerOneLine } from "./subcomponent/code-container.js"

# The following "get agent set reporter" functions return a string of interpretable NetLogo code referring to each
# the agents passed in.

# (string, (Agent) -> string) -> (Array[Agent]) -> string
getAgentSetReporterCreator = (setName, getAgentReporter) -> (agents) ->
  "(#{setName} #{(for agent in agents then getAgentReporter(agent)).join(' ')})"
# (Array[Agent]) -> string
getTurtleSetReporter = getAgentSetReporterCreator(
  'turtle-set',
  (turtle) -> "turtle #{turtle.id}"
)
getPatchSetReporter = getAgentSetReporterCreator(
  'patch-set',
  (patch) -> "patch #{patch.pxcor} #{patch.pycor}"
)
getLinkSetReporter = getAgentSetReporterCreator(
  'link-set',
  (link) -> "#{link.getBreedNameSingular()} #{link.end1.id} #{link.end2.id}"
)

# (TargetedAgentObj, string) -> string
getCommand = (targetedAgentObj, input) ->
  { agentType, agents } = targetedAgentObj
  if agentType is 'observer'
    # Just send the command as-is.
    input
  else if agents?
    # Construct a specific agentset to send the command to.

    # (Array[Agent]) -> string
    getAgentSetReporter = switch agentType
      when 'turtles' then getTurtleSetReporter
      when 'patches' then getPatchSetReporter
      when 'links' then getLinkSetReporter
      else throw new Error("#{agentType} is not a valid agent type")

    agentSetReporter = getAgentSetReporter(agents)

    "ask #{agentSetReporter} [ #{input} ]"
  else
    # Send the command to all agents of the specified types
    "ask #{agentType} [ #{input} ]"

# type Entry = { targetedAgentObj: TargetedAgentObj, input: string }

# Returns whether the two entries have the same agent targeting and the same input
# (Entry, Entry) -> boolean
compareEntries = (a, b) ->
  { input: aInput, targetedAgentObj: { agentType: aAgentType, agents: aAgents } } = a
  { input: bInput, targetedAgentObj: { agentType: bAgentType, agents: bAgents } } = b
  if aInput isnt bInput then return false
  if aAgentType isnt bAgentType then return false
  if aAgents? isnt bAgents? then return false
  if not aAgents? then return true
  aAgents.every((el) -> bAgents.includes(el)) and bAgents.every((el) -> aAgents.includes(el))

RactiveCommandInput = Ractive.extend({
  components: {
    codeContainer: RactiveCodeContainerOneLine
  }

  # AgentType = 'observer' | 'turtles' | 'patches' | 'links'

  data: -> {
    # Props

    source:             undefined # string; where the command came from, e.g. 'console'
    checkIsReporter:    undefined # (string) -> boolean
    isReadOnly:         undefined # boolean
    placeholderText:    undefined # string
    visiblePlaceholder: undefined # string; placeholder text shown in the editor when empty

    # Shared State (both this component and the enclosing root component can read/write)

    # Modifications to this property should reassign it to a completely new object, instead
    # of mutating the existing object. This is because this object will be stored in the history.
    # The `agentType` property determines the type of agent that will be targeted by this
    # commands runs by this command input. If 'observer', then `agents` is ignored
    # and commands are sent to the observer. If either 'turtles', 'patches', or 'links',
    # then commands are sent to those agents in `agents` (which must be of the correct
    # type), unless `agents` is undefined in which case it is sent to all agents of
    # that type.
    # type TargetedAgentObj = { agentType: AgentType, agents?: Array[Agent] }
    targetedAgentObj: { agentType: 'observer' }

    history:      [] # Array[Entry]; highest index is most recent
    historyIndex: 0  # keyof typeof @get('history') | @get('history').length
    workingEntry: {} # stores Entry when the user up-arrows
  }

  computed: {
    # string
    input: {
      get: -> @findComponent('codeContainer').get('code')
      set: (newValue) -> @findComponent('codeContainer').setCode(newValue)
    }
  }

  on: {
    complete: ->
      editor = @findComponent('codeContainer').getEditor()
      if editor?
        editor.addKeyMap({
          'Enter': =>
            @run()
            false
          'Tab': =>
            if @get('input').length is 0
              @fire('command-input-tabbed')
              false
            else
              CodeMirror.Pass
          'Up': =>
            @moveInHistory(-1)
            false
          'Down': =>
            @moveInHistory(1)
            false
        })
        visiblePlaceholder = @get('visiblePlaceholder')
        if visiblePlaceholder?
          editor.setOption('placeholder', visiblePlaceholder)
      return
  }

  observe: {
    visiblePlaceholder: (newText) ->
      editor = @findComponent('codeContainer').getEditor()
      editor?.setOption('placeholder', newText ? '')
  }

  run: ->
    input = @get('input')
    if input.trim().length > 0
      targetedAgentObj = @get('targetedAgentObj')
      if @get('checkIsReporter')(input)
        input = "show #{input}"

      history = @get('history')
      newEntry = { targetedAgentObj, input }
      if history.length is 0 or not compareEntries(history.at(-1), newEntry)
        history.push(newEntry)
      @set('historyIndex', history.length)

      cmd = getCommand(targetedAgentObj, input)
      @fire('run', {}, @get('source'), cmd, { targetedAgentObj, input })
      @fire('command-center-run', cmd)
    @set({ input: "", workingEntry: {} })

  moveInHistory: (delta) ->
    history = @get('history')
    currentIndex = @get('historyIndex')
    newIndex = Math.max(Math.min(currentIndex + delta, history.length), 0)
    if currentIndex is history.length
      # The current entry is not in history; save it before moving to history
      @set('workingEntry', { input: @get('input') })
    { input } = if newIndex is history.length
      # Moving out of history to the working entry
      @get('workingEntry')
    else
      # Moving to some point in history
      history[newIndex]
    @set({ input, historyIndex: newIndex })

  # (Unit) -> Unit
  focus: ->
    @findComponent('codeContainer').focus()
    return

  template: """
    <div class="netlogo-command-center-editor">
      <codeContainer
        initialCode=""
        isDisabled={{isReadOnly}}
        aria-label="{{placeholderText}}"
      />
    </div>
  """
})

export default RactiveCommandInput

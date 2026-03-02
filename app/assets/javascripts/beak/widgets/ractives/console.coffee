import RactivePrintArea from "./subcomponent/print-area.js"
import RactiveCommandInput from "./command-input.js"

RactiveConsoleWidget = Ractive.extend({
  components: {
    printArea: RactivePrintArea
    commandInput: RactiveCommandInput
  }

  # types AgentType and TargetedAgentObj is defined in "./command-input.coffee"

  data: -> {
    # Props
    isEditing: undefined # boolean (for widget editing)
    checkIsReporter: undefined # (String) => Boolean

    # Shared State
    output: ''

    # Private State
    agentTypeIndex: 0 # keyof typeof @get('agentTypes')

    # Consts
    agentTypes: ['observer', 'turtles', 'patches', 'links'] # Array[AgentType]
  }

  computed: {
    # AgentType
    agentType: {
      get: -> @get('agentTypes')[@get('agentTypeIndex')]
      set: (val) ->
        index = @get('agentTypes').indexOf(val)
        if index >= 0
          @set('agentTypeIndex', index)
    }

    # TargetedAgentObj
    targetedAgentObj: {
      get: -> { agentType: @get('agentType') }
      set: ({ agentType }) ->
        # intentionally ignore the `agents` property of the input
        @set('agentType', agentType)
    }

    # string
    placeholderText: ->
      "Input command for " + switch @get('agentType')
        when 'observer' then "the observer"
        when 'turtles' then "all turtles"
        when 'patches' then "all patches"
        when 'links' then "all links"
  }

  # String -> Unit
  appendText: (str) ->
    @set('output', @get('output') + str)
    return

  on: {
    'clear-output': ->
      @set('output', "")
    'commandInput.run': (_, _source, _cmd, { targetedAgentObj, input }) ->
      # Use `targetedAgentObj` from the event instead of `@get('targetedAgentObj')` because we don't know if the
      # component modified the shared state before firing this event. (It doesn't, but the point is that it could).
      { agentType } = targetedAgentObj # ignore the `agents` property of the object
      @appendText("#{agentType}> #{input}\n")
      true # propagate event
    'commandInput.command-input-tabbed': ->
      @set('agentTypeIndex', (@get('agentTypeIndex') + 1) % @get('agentTypes').length)
      false
    'focus-command-input': ->
      @findComponent('commandInput').focus()
      false
  }

  template:
    """
    <div class='netlogo-tab-content netlogo-command-center'
         grow-in='{disable:"console-toggle"}' shrink-out='{disable:"console-toggle"}'>
      <printArea id='command-center-print-area' output='{{output}}'/>

      <div class='netlogo-command-center-input'>
        <select value="{{agentType}}" on-change="focus-command-input">
        {{#agentTypes}}
          <option value="{{.}}">{{.}}</option>
        {{/}}
        </select>
        <commandInput
          isReadOnly={{isEditing}}
          source="console"
          checkIsReporter={{checkIsReporter}}
          targetedAgentObj={{targetedAgentObj}}
          placeholderText={{placeholderText}}
        />
        <button on-click='clear-output'>Clear</button>
      </div>
    </div>
    """
})

export default RactiveConsoleWidget

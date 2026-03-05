import { toNetLogoString } from "../../tortoise-utils.js"

Turtle = tortoise_require('engine/core/turtle')
Patch = tortoise_require('engine/core/patch')
Link = tortoise_require('engine/core/link')

RactiveAgentVarField = Ractive.extend({
  data: -> {
    # Props
    agent: undefined # Agent; (from the actual agent)
    varName: undefined # string; as in `agent.hasVariable(varName)`

    # State
    currentInput: undefined
    hasFocus: false
  }

  computed: {
    varValueAsStr: ->
      agent = @get('agent')
      return '' unless agent?
      val = agent.getVariable(@get('varName'))
      if typeof val is 'string'
        "\"#{val}\""
      else
        # assume that the value is convertible to a string
        "#{val}"

    # Whether this variable being tracked is a special case variable. If not, then this value is 'NORMAL' and
    # editing the value just asks the agent to set the variable. However, if it is the coordinate of a patch, or the
    # who number of a turtle or link, then editing the value will cause the inspection window to switch agents.
    # 'NORMAL' | 'AGENT_SWITCH'
    editEffect: ->
      agent = @get('agent')
      varName = @get('varName')
      if (
        (agent instanceof Turtle and varName is 'who') or
        (agent instanceof Patch and (varName is 'pxcor' or varName is 'pycor')) or
        (agent instanceof Link and (varName is 'end1' or varName is 'end2' or varName is 'breed'))
      )
        'AGENT_SWITCH'
      else
        'NORMAL'
  }

  observe: {
    'varValueAsStr': (value) ->
      if not @get('hasFocus')
        @set('currentInput', value)
  }

  on: {
    'submit-input': (_, input) ->
      if input.trim().length > 0
        varName = @get('varName')
        switch @get('editEffect')
          when 'NORMAL'
            sanitizedInput = toNetLogoString(input)
            cmd = "ask #{@get('agent').getName()} [ set #{varName} runresult #{sanitizedInput}]"
            @fire('run', {}, 'agent-var-field', cmd)
            @update('varValueAsStr')
          when 'AGENT_SWITCH'
            @fire('agent-id-var-changed', {}, varName, input)
      @set('currentInput', @get('varValueAsStr'))
      return
  }

  template: """
    <div class="inspection__agent-var-name" title="{{varName}}">{{varName}}</div>
    <input class="inspection__input-container" value={{currentInput}}
           on-focus="@this.set('hasFocus', true)"
           on-blur="@this.set('hasFocus', false)"
           on-change="['submit-input', currentInput]"/>
  """
})

export default RactiveAgentVarField

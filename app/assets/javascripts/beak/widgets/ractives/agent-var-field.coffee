import { dumpValue, toNetLogoString } from "../../tortoise-utils.js"
import { RactiveCodeContainerOneLine } from "./subcomponent/code-container.js"

Turtle = tortoise_require('engine/core/turtle')
Patch = tortoise_require('engine/core/patch')
Link = tortoise_require('engine/core/link')

RactiveAgentVarField = Ractive.extend({
  components: {
    codeContainer: RactiveCodeContainerOneLine
  }

  data: -> {
    # Props
    agent:          undefined # Agent
  , varName:        undefined # String

    # State
  , currentInput:   undefined                    # String
  , hasFocus:       false                        # Boolean
  , varFieldConfig: { scrollbarStyle: 'null' }   # Object
  }

  computed: {
    # () -> String
    varValueAsStr: ->
      agent = @get('agent')
      return '' unless agent?
      val = agent.getVariable(@get('varName'))
      dumpValue(val)

    # Whether this variable being tracked is a special case variable. If not, then this value is 'NORMAL' and
    # editing the value just asks the agent to set the variable. However, if it is the coordinate of a patch, or the
    # who number of a turtle or link, then editing the value will cause the inspection window to switch agents.
    # () -> 'NORMAL' | 'AGENT_SWITCH'
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
        @findComponent('codeContainer')?.setCode(value)
      return
  }

  on: {
    complete: ->
      editor = @findComponent('codeContainer').getEditor()
      if editor?
        editor.on('focus', => @set('hasFocus', true))
        editor.on('blur', =>
          @set('hasFocus', false)
          @fire('submit-input', {}, editor.getValue())
        )
        editor.addKeyMap({
          'Enter': =>
            @fire('submit-input', {}, editor.getValue())
            false
        })
      return

    'submit-input': (_, input) ->
      if input.trim().length > 0 and input isnt @get('varValueAsStr')
        varName = @get('varName')
        switch @get('editEffect')
          when 'NORMAL'
            sanitizedInput = toNetLogoString(input)
            cmd = "ask #{@get('agent').getName()} [ set #{varName} runresult #{sanitizedInput}]"
            @fire('run', {}, 'agent-var-field', cmd)
            @update('varValueAsStr')
          when 'AGENT_SWITCH'
            @fire('agent-id-var-changed', {}, varName, input)
      val = @get('varValueAsStr')
      @set('currentInput', val)
      @findComponent('codeContainer')?.setCode(val)
      return
  }

  template: """
    <div class="inspection-agent-var-name" title="{{varName}}">{{varName}}</div>
    <div class="inspection-input-container">
      <codeContainer initialCode="{{currentInput}}" localConfig="{{varFieldConfig}}" />
    </div>
  """
})

export default RactiveAgentVarField

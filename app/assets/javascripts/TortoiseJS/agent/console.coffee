window.ConsoleWidget = Ractive.extend({
  data: {
    input: '',
    agentTypes: ['observer', 'turtles', 'patches', 'links'],
    agentTypeIndex: 0,
    history: [], # Array of {agentType, input} objects
    historyIndex: 0,
    workingEntry: {}, # Stores {agentType, input} when user up arrows
    output: ''
  }

  isolated: true

  computed: {
    agentType: {
      get: -> @get('agentTypes')[@get('agentTypeIndex')]
      set: (val) ->
        index = @get('agentTypes').indexOf(val)
        if index >= 0
          @set('agentTypeIndex', index)
    }
  }

  components: {
    outputArea: OutputArea
  }

  onrender: ->
    changeAgentType = =>
      @set('agentTypeIndex', (@get('agentTypeIndex') + 1) % @get('agentTypes').length)

    moveInHistory = (index) =>
      newIndex = @get('historyIndex') + index
      if newIndex < 0
        newIndex = 0
      else if newIndex > @get('history').length
        newIndex = @get('history').length
      if @get('historyIndex') == @get('history').length
        @set('workingEntry', {agentType: @get('agentType'), input: @get('input')})
      if newIndex == @get('history').length
        @set(@get('workingEntry'))
      else
        entry = @get('history')[newIndex]
        @set(entry)
      @set('historyIndex', newIndex)

    run = =>
      input = @get('input')
      if input.trim().length > 0
        agentType = @get('agentType')
        @set('output', "#{@get('output')}#{agentType}> #{input}\n")
        history = @get('history')
        lastEntry = if history.length > 0 then history[history.length - 1] else {agentType: '', input: ''}
        if lastEntry.input != input or lastEntry.agentType != agentType
          history.push({agentType, input})
        @set('historyIndex', history.length)
        if agentType != 'observer'
          input = "ask #{agentType} [ #{input} ]"
        @fire('run', input)
        @set('input', '')
        @set('workingEntry', {})

    @on('clear-history', (event) ->
      @set('output', '')
    )

    commandCenterEditor = CodeMirror(@find('.netlogo-command-center-editor'), {
      value: @get('input'),
      mode:  'netlogo',
      theme: 'netlogo-default',
      extraKeys: {
        Enter: run
        Up:    => moveInHistory(-1)
        Down:  => moveInHistory(1)
        Tab:   => changeAgentType()
      }
    })

    commandCenterEditor.on('change', =>
      @set('input', commandCenterEditor.getValue())
    )

    @observe('input', (newValue) ->
      if newValue != commandCenterEditor.getValue()
        commandCenterEditor.setValue(newValue)
        commandCenterEditor.execCommand('goLineEnd')
    )

  template:
    """
    <div class='netlogo-command-center netlogo-widget'>
      <outputArea output='{{output}}'/>

      <div class='netlogo-command-center-input'>
        <label>
          <select value="{{agentType}}">
          {{#agentTypes}}
            <option value="{{.}}">{{.}}</option>
          {{/}}
          </select>
        </label>
        <div class="netlogo-command-center-editor"></div>
        <button on-click='clear-history'>Clear</button>
      </div>
    </div>
    """
})

ENTER_KEY = 13
TAB_KEY = 9
UP_KEY = 38
DOWN_KEY = 40

window.RactiveConsoleWidget = Ractive.extend({
  data: -> {
    input: '',
    isEditing: undefined # Boolean (for widget editing)
    agentTypes: ['observer', 'turtles', 'patches', 'links'],
    agentTypeIndex: 0,
    checkIsReporter: undefined # (String) => Boolean
    history: [], # Array of {agentType, input} objects
    historyIndex: 0,
    workingEntry: {}, # Stores {agentType, input} when user up arrows
    output: ''
  }

  computed: {
    agentType: {
      get: -> @get('agentTypes')[@get('agentTypeIndex')]
      set: (val) ->
        index = @get('agentTypes').indexOf(val)
        if index >= 0
          @set('agentTypeIndex', index)
          @focusCommandCenterEditor()
    }
  }

  components: {
    printArea: RactivePrintArea
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
      if @get('historyIndex') is @get('history').length
        @set('workingEntry', {agentType: @get('agentType'), input: @get('input')})
      if newIndex is @get('history').length
        @set(@get('workingEntry'))
      else
        entry = @get('history')[newIndex]
        @set(entry)
      @set('historyIndex', newIndex)

    consoleErrorLog = (messages) =>
      @set('output', "#{@get('output')}ERROR: #{messages.join('\n')}\n")

    run = =>
      input = @get('input')
      if input.trim().length > 0
        agentType = @get('agentType')
        if @get('checkIsReporter')(input)
          input = "show #{input}"
        @set('output', "#{@get('output')}#{agentType}> #{input}\n")
        history = @get('history')
        lastEntry = if history.length > 0 then history[history.length - 1] else {agentType: '', input: ''}
        if lastEntry.input isnt input or lastEntry.agentType isnt agentType
          history.push({agentType, input})
        @set('historyIndex', history.length)
        if agentType isnt 'observer'
          input = "ask #{agentType} [ #{input} ]"
        @fire('run', {}, input, consoleErrorLog)
        @set('input', '')
        @set('workingEntry', {})

    @on('clear-history', ->
      @set('output', '')
    )

    commandCenterEditor = CodeMirror(@find('.netlogo-command-center-editor'), {
      value: @get('input'),
      mode:  'netlogo',
      theme: 'netlogo-default',
      scrollbarStyle: 'null',
      extraKeys: {
        Enter: run
        Up:    => moveInHistory(-1)
        Down:  => moveInHistory(1)
        Tab:   => changeAgentType()
      }
    })

    @focusCommandCenterEditor = () -> commandCenterEditor.focus()

    commandCenterEditor.on('beforeChange', (_, change) ->
      oneLineText = change.text.join('').replace(/\n/g, '')
      change.update(change.from, change.to, [oneLineText])
      true
    )

    commandCenterEditor.on('change', =>
      @set('input', commandCenterEditor.getValue())
    )

    @observe('input', (newValue) ->
      if newValue isnt commandCenterEditor.getValue()
        commandCenterEditor.setValue(newValue)
        commandCenterEditor.execCommand('goLineEnd')
    )

    @observe('isEditing', (isEditing) ->
      commandCenterEditor.setOption('readOnly', if isEditing then 'nocursor' else false)
      classes = this.find('.netlogo-command-center-editor').querySelector('.CodeMirror-scroll').classList
      if isEditing
        classes.add('cm-disabled')
      else
        classes.remove('cm-disabled')
      return
    )

  # String -> Unit
  appendText: (str) ->
    @set('output', @get('output') + str)
    return

  template:
    """
    <div class='netlogo-tab-content netlogo-command-center'
         grow-in='{disable:"console-toggle"}' shrink-out='{disable:"console-toggle"}'>
      <printArea id='command-center-print-area' output='{{output}}'/>

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

window.RactiveNetLogoCodeInput = Ractive.extend({

  _editor: undefined # CodeMirror

  data: -> {

    initialAskee:  undefined # String
  , askee:         undefined # String

  , initialInput:  ''        # String
  , input:         undefined # String

  , history:        [] # Array of { askee, input } objects
  , historyIndex:   0
  , workingEntry:   {} # Stores { askee, input } when user up-arrows

  , cmConfig: undefined # Object

  , class: undefined # String
  , id:    undefined # String
  , style: undefined # String

  }

  isolated: true

  # Avoid two-way binding complications --JAB (7/7/16)
  oninit: ->
    @set('askee', @get('initialAskee') ? @get('askee'))
    @set('input', @get('initialInput') ? @get('input'))
    return

  onrender: ->

    template = {
      extraKeys: {
        Enter:       => @_run()
        Up:          => @_moveInHistory(-1)
        Down:        => @_moveInHistory(1)
        Tab:         => @fire('tab-key')
        'Shift-Tab': false
      }
    , mode:           'netlogo'
    , scrollbarStyle: 'null'
    , theme:          'netlogo-default'
    , value:          @get('input')
    }

    config = Object.assign({}, template, @get('cmConfig'))
    @_editor = CodeMirror(@find('.netlogo-code-input'), config)

    @_editor.on('change', =>
      @set('input', @_editor.getValue())
    )

    @observe('input', (newValue) ->
      if newValue isnt @_editor.getValue()
        @_editor.setValue(newValue)
        @_editor.execCommand('goLineEnd')
    )

    return

  # Unit -> Unit
  refresh: ->
    @_editor.refresh()
    return

  _moveInHistory: (index) ->

    attenuate = (min, max, number) ->
      if number < min then min else if number > max then max else number

    newIndex = attenuate(0, @get('history').length, @get('historyIndex') + index)

    if @get('historyIndex') is @get('history').length
      @set('workingEntry', { askee: @get('askee'), input: @get('input') })

    { askee, input } =
      if newIndex is @get('history').length
        @get('workingEntry')
      else
        @get('history')[newIndex]

    @set('input',        input)
    @set('askee',        askee)
    @set('historyIndex', newIndex)

    return

  _run: ->

    input = @get('input')

    if input.trim().length > 0

      askee   = @get('askee')
      history = @get('history')

      { askee: lastAskee, input: lastInput } =
        if history.length > 0
          history[history.length - 1]
        else
          { askee: '', input: '' }

      if lastInput isnt input or lastAskee isnt askee
        history.push({ askee, input })

      code =
        if askee isnt 'observer'
          "ask #{askee} [ #{@_wrapInput(input)} ]"
        else
          input

      @set('historyIndex', history.length)
      @set('input',        '')
      @set('workingEntry', {})

      @fire('add-output-line', askee, input)
      @fire('run-code', code)

    return

  _wrapInput: (input) ->
    input

  template:
    """
    <div {{ # id }} id="{{id}}"{{/}} class="netlogo-code-input {{class}}" style="{{style}}"></div>
    """

})

window.RactiveConsoleWidget = Ractive.extend({
  data: -> {
    input: '',
    isEditing: undefined # Boolean (for widget editing)
    agentTypes: ['observer', 'turtles', 'patches', 'links'],
    agentTypeIndex: 0,
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
        if Converter.isReporter(input)
          input = "show #{input}"
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

    commandCenterEditor.on('change', =>
      @set('input', commandCenterEditor.getValue())
    )

    @observe('input', (newValue) ->
      if newValue != commandCenterEditor.getValue()
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

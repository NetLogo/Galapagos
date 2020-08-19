window.RactiveJsonEditor = Ractive.extend({
  data: () -> {
    id:      ""    # String
    show:    false # Boolean
    json:    ""    # String
    newJson: ""    # String
    isDirty: false # Boolean
  }

  on: {

    # (Context) => Unit
    'render': (_) ->
      config = {
        mode: { name: 'javascript', json: true },
        theme: 'netlogo-default',
        lineNumbers: true,
        value: @get('json'),
        fixedGutter: true
      }
      element = @find("##{@get('id')}")
      editor = new CodeMirror(element, config)

      editor.on('change', () =>
        newJson = editor.getValue()
        @set('newJson', newJson)
        json = @get('json')
        @set('isDirty', json isnt newJson)
        return
      )

      showHandler = (newValue) =>
        if (newValue)
          editor.refresh()
          editor.focus()
        return
      @observe('show', showHandler, { defer: true })

      setHandler = (newValue) =>
        if (newValue is undefined or newValue is null) then return
        @set('isDirty', false)
        newJson = editor.getValue()
        if (newJson isnt newValue)
          editor.setValue(newValue)
        return
      @observe('json', setHandler)

      return
  }

  template:
    """
    <div class="ntb-block-defs-controls">

      <label class="ntb-toggle-block" >
        <input id="info-toggle" type="checkbox" checked="{{ show }}" />
        <div>{{# show }}▲{{else}}▼{{/}} Block Space Definition</div>
      </label>

      {{# show }}
      <button class="ntb-button" type="button"
        on-click="[ 'ntb-apply-json-to-space', newJson ]"
        {{# !isDirty }} disabled{{/}}>
        Apply Definition to Space
      </button>
      {{/ show }}

    </div>

    <div id={{ id }} class="ntb-json" {{# !show }}style="display: none;"{{/ !show }} />
    """

})

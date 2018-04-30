ChooserEditForm = EditForm.extend({

  data: -> {
    choices: undefined # String
  , display: undefined # String
  }

  twoway: false

  components: {
    formCode:     RactiveEditFormMultilineCode
  , formVariable: RactiveEditFormVariable
  }

  computed: {
    chooserChoices: {
      get: -> @get('choices').map((x) -> workspace.dump(x, true)).join('\n')
    }
  }

  genProps: (form) ->
    varName    = form.varName.value
    choices    = @findComponent('formCode').findComponent('codeContainer').get('code')
    choicesArr = Converter.stringToJSValue("[#{choices}]")
    {
       choices: choicesArr
    ,  display: varName
    , variable: varName.toLowerCase()
    }

  partials: {

    title: "Chooser"

    widgetFields:
      """
      <formVariable id="{{id}}-varname" value="{{display}}"        name="varName" />
      <formCode     id="{{id}}-choices" value="{{chooserChoices}}" name="codeChoices"
                    label="Choices" config="{}" style="" />
      """

  }

})

window.RactiveChooser = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , resizeDirs:         ['left', 'right']
  }

  components: {
    editForm: ChooserEditForm
  }

  eventTriggers: ->
    recompileEvent =
      if @findComponent('editForm').get('amProvingMyself') then @_weg.recompileLite else @_weg.recompile
    {
       choices: [@_weg.refreshChooser]
    , variable: [recompileEvent, @_weg.rename]
    }

  minWidth:  55
  minHeight: 45

  # coffeelint: disable=max_line_length
  template:
    """
    {{>editorOverlay}}
    <label id="{{id}}" class="netlogo-widget netlogo-chooser netlogo-input {{classes}}" style="{{dims}}">
      <span class="netlogo-label">{{widget.display}}</span>
      <select class="netlogo-chooser-select" value="{{widget.currentValue}}"{{# isEditing }} disabled{{/}} >
      {{#widget.choices}}
        <option class="netlogo-chooser-option" value="{{.}}">{{>literal}}</option>
      {{/}}
      </select>
    </label>
    <editForm idBasis="{{id}}" choices="{{widget.choices}}" display="{{widget.display}}" />
    """

  partials: {

    literal:
      """
      {{# typeof . === "string"}}{{.}}{{/}}
      {{# typeof . === "number"}}{{.}}{{/}}
      {{# typeof . === "boolean"}}{{.}}{{/}}
      {{# typeof . === "object"}}
        [{{#.}}
          {{>literal}}
        {{/}}]
      {{/}}
      """

  }
  # coffeelint: enable=max_line_length

})

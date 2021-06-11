dump = (x, y) ->
  if Array.isArray(x)
    "[#{x.map(dump).join(' ')}]"
  else if typeof(x) is "string"
    "\"#{x}\""
  else if typeof(x) in ["boolean", "number"]
    x
  else
    workspace.dump(x, y)

ChooserEditForm = EditForm.extend({

  data: -> {
    choices: undefined # String
  , display: undefined # String
  , setHiddenInput: ( # We do this so we can validate the contents of the CodeMirror input --JAB (5/14/18)
      (code) ->
        elem        = this.find("##{@get('id')}-choices-hidden")
        elem.value  = code
        validityStr =
          try
            Converter.stringToJSValue("[#{code}]")
            ""
          catch ex
            "Invalid format: Must be a space-separated list of NetLogo literal values"
        elem.setCustomValidity(validityStr)
    )
  }

  twoway: false

  components: {
    formCode:     RactiveEditFormMultilineCode
  , formVariable: RactiveEditFormVariable
  , spacer:       RactiveEditFormSpacer
  }

  computed: {
    chooserChoices: {
      get: -> @get('choices').map((x) -> dump(x, true)).join('\n')
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

    codeInput:
      """
      <formCode id="{{id}}-choices" value="{{chooserChoices}}" name="codeChoices"
                label="Choices" config="{}" style="" onchange="{{setHiddenInput}}" />
      """

    variableForm:
      """
      <formVariable id="{{id}}-varname" name="varName" label="Global variable" value="{{display}}" />
      """

    widgetFields:
      """
      {{>variableForm}}
      <spacer height="15px" />
      {{>codeInput}}
      <input id="{{id}}-choices-hidden" name="trueCodeChoices" class="all-but-hidden"
             style="margin: -5px 0 0 7px;" type="text" />
      <div class="widget-edit-hint-text">Example: "a" "b" "c" 1 2 3</div>
      """

  }

})

HNWChooserEditForm = ChooserEditForm.extend({

  components: {
    formDropdown: RactiveEditFormDropdown
  }

  computed: {
    sortedBreedVars: {
      get: -> @get('breedVars').slice(0).sort()
      set: (x) -> @set('breedVars', x)
    }
  }

  data: -> {
    breedVars: undefined # Array[String]
  }

  genProps: (form) ->
    varName    = form.varName.value
    choices    = @findComponent('formCode').findComponent('codeContainer').get('code')
    # choicesArr = Converter.stringToJSValue("[#{choices}]")
    # TODO: This requires access to the compiler, which lives in the parent frame....
    # Jason B. (5/24/21)
    {
       display: varName
    , variable: varName.toLowerCase()
    }

  on: {
    'use-new-var': (_, varName) ->
      @set('display',  varName)
      @set('variable', varName.toLowerCase())
      return
  }

  partials: {

    codeInput:
      """
      <formCode id="{{id}}-choices" value="{{chooserChoices}}" name="codeChoices" isDisabled="true"
                label="Choices" config="{}" style="" onchange="{{setHiddenInput}}" />
      """

    variableForm:
      """
      <div class="flex-row">
        <formDropdown id="{{id}}-varname" name="varName" label="Turtle variable"
                      choices="{{sortedBreedVars}}" selected="{{display}}" />
        <button on-click="@this.fire('add-breed-var', @this)" type="button" style="height: 30px;">Define New Variable</button>
      </div>
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
    <editForm idBasis="{{id}}" choices="{{widget.choices}}" display="{{widget.display}}" breedVars="{{breedVars}}" />
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

window.RactiveHNWChooser = RactiveChooser.extend({
  components: {
    editForm: HNWChooserEditForm
  }
})

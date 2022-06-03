import RactiveValueWidget from "./value-widget.js"
import EditForm from "./edit-form.js"
import { RactiveEditFormMultilineCode } from "./subcomponent/code-container.js"
import { RactiveEditFormDropdown } from "./subcomponent/dropdown.js"
import RactiveEditFormSpacer from "./subcomponent/spacer.js"
import RactiveEditFormVariable from "./subcomponent/variable.js"

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
  , setHiddenInput: ( # We do this so we can validate the contents of the CodeMirror input --Jason B. (5/14/18)
      (code) ->
        elem        = this.find("##{@get('id')}-choices-hidden")
        elem.value  = code
        validityStr =
          try
            @_reify(code)
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
    choicesArr = @_reify(choices)
    {
       choices: choicesArr
    ,  display: varName
    , variable: varName.toLowerCase()
    }

  _reify: (choices) ->
    Converter.stringToJSValue("[#{choices}]")

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

  on: {
    'use-new-var': (_, varName) ->
      @set('display',  varName)
      @set('variable', varName.toLowerCase())
      return
  }

  _reify: (choices) ->
    window.parent.Converter.stringToJSValue("[#{choices}]")

  partials: {

    codeInput:
      """
      <formCode id="{{id}}-choices" value="{{chooserChoices}}" name="codeChoices"
                label="Choices" config="{}" style="" onchange="{{setHiddenInput}}" />
      """

    variableForm:
      """
      <div class="flex-row">
        <formDropdown id="{{id}}-varname" name="varName" label="Turtle variable"
                      choices="{{sortedBreedVars}}" selected="{{display}}" />
        <button on-click="@this.fire('add-breed-var', @this)"
                type="button" style="height: 30px;">Define New Variable</button>
      </div>
      """

  }

})

RactiveChooser = RactiveValueWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , resizeDirs:         ['left', 'right']
  }

  widgetType: "chooser"

  observe: {
    'widget.currentValue': () ->
      widget        = @get('widget')
      currentChoice = widget.choices.findIndex( (c) -> c is widget.currentValue )
      @set('widget.currentChoice', if currentChoice >= 0 then currentChoice else 0)
      return
  }

  components: {
    editForm: ChooserEditForm
  }

  eventTriggers: ->
    {
       choices: [@_weg.refreshChooser]
    , variable: [@_weg.recompile, @_weg.rename]
    }

  minWidth:  55
  minHeight: 45

  # coffeelint: disable=max_line_length
  template:
    """
    {{>editorOverlay}}
    <label id="{{id}}" class="netlogo-widget netlogo-chooser netlogo-input {{classes}}" style="{{dims}}">
      <span class="netlogo-label">{{widget.display}}</span>
      <select
        class="netlogo-chooser-select"
        value="{{internalValue}}"
        on-change="widget-value-change"
        {{# isEditing }} disabled{{/}} >
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

RactiveHNWChooser = RactiveChooser.extend({
  components: {
    editForm: HNWChooserEditForm
  }
})

export { RactiveChooser, RactiveHNWChooser }

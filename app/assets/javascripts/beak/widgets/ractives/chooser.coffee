import RactiveValueWidget from "./value-widget.js"
import EditForm from "./edit-form.js"
import { RactiveEditFormMultilineCode } from "./subcomponent/code-container.js"
import { RactiveEditFormDropdown } from "./subcomponent/dropdown.js"
import { RactiveEditFormCheckbox } from "./subcomponent/checkbox.js"
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
  , oldSize: undefined # Boolean
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
  , formCheckbox: RactiveEditFormCheckbox
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
    ,  oldSize: form.oldSize.checked
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
      <spacer height="15px" />
      <formCheckbox id="{{id}}-old-size" isChecked="{{ oldSize }}" labelText="Use old widget sizing"
                  name="oldSize" />
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
    internalChoice: 0
  }

  widgetType: "chooser"

  _setChoice: (idx, { setInternalValue = true } = {}) ->
    # This method syncs up values but control of side effects
    # is up to the caller via the setInternalValue option and
    # the choice to call @fire('widget-value-change') or not.
    widget          = @get('widget')
    valid           = idx >= 0 and idx < widget.choices.length
    choice          = widget.choices[idx]

    if setInternalValue
      @set('internalValue', choice)
    @set('internalChoice', idx)
    @set('widget.currentChoice', if valid then idx else 0)
    choice

  refreshChooser: (myself) -> (_, _1, chooser) ->
    if myself.get('widget') is chooser
      { eq } = tortoise_require('brazier/equals')
      chooser.currentChoice = Math.max(0, chooser.choices.findIndex(eq(chooser.currentValue)))
      myself.set('internalChoice', chooser.currentChoice)

  on: {
    'init': ->
      widget = @get('widget')
      @_setChoice(widget.currentChoice)
      @root.on('*.refresh-chooser', @refreshChooser(this))

    'chooser-option-change': (event) ->
      @_setChoice(parseInt(event.node.value))
      @fire('widget-value-change')
  }

  observe: {
    'widget.currentValue': () ->
      widget    = @get('widget')
      idx       = widget.choices.findIndex((c) -> c is widget.currentValue)
      if widget.choices[idx] is widget.choices[@get('internalChoice')]
        return # NOOP
      @_setChoice(idx, { setInternalValue: false })
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
    <label id="{{id}}" class="netlogo-widget netlogo-chooser netlogo-input {{#widget.oldSize}}old-size{{/}} {{classes}}" style="{{dims}}">
      <span class="netlogo-label">{{widget.display}}</span>
      <select
        name="chooser"
        class="netlogo-chooser-select"
        value="{{internalChoice}}"
        on-change="chooser-option-change"
        {{# isEditing }} disabled{{/}} >
        {{#widget.choices:index}}
        <option class="netlogo-chooser-option" value="{{index}}">{{>literal}}</option>
        {{/}}
      </select>
    </label>
    <editForm idBasis="{{id}}" choices="{{widget.choices}}" display="{{widget.display}}" breedVars="{{breedVars}}" oldSize="{{widget.oldSize}}" />
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

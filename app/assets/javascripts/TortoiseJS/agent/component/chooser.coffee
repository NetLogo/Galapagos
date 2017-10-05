ChooserEditForm = EditForm.extend({

  data: -> {
    choices: undefined # String
  , display: undefined # String
  }

  twoway: false

  components: {
    formCode:     RactiveEditFormCodeContainer
  , formVariable: RactiveEditFormVariable
  }

  computed: {
    chooserChoices: {
      get: -> @get('choices').map((x) -> workspace.dump(x, true)).join('\n')
    }
  }

  validate: (form) ->
    varName    = form.varName.value
    choices    = @findComponent('formCode').findComponent('codeContainer').get('code')
    choicesArr = Converter.stringToJSValue("[#{choices}]")
    {
      triggers: {
        variable: [WidgetEventGenerators.recompile, WidgetEventGenerators.rename]
      }
    , values: {
        choices:  choicesArr
      , display:  varName
      , variable: varName.toLowerCase()
      }
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
  }

  components: {
    editForm: ChooserEditForm
  }

  template:
    """
    <label id="{{id}}"
           on-contextmenu="@this.fire('showContextMenu', @event)"
           class="netlogo-widget netlogo-chooser netlogo-input"
           style="{{dims}}">
      <span class="netlogo-label">{{widget.display}}</span>
      <select class="netlogo-chooser-select" value="{{widget.currentValue}}">
      {{#widget.choices}}
        <option class="netlogo-chooser-option" value="{{.}}">{{>literal}}</option>
      {{/}}
      </select>
    </label>
    <editForm idBasis="{{id}}" choices="{{widget.choices}}" display="{{widget.display}}"/>
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

})

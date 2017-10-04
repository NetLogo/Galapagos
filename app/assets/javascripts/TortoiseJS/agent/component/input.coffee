InputEditForm = EditForm.extend({

  data: -> {
    boxtype:     undefined # String
  , display:     undefined # String
  , isMultiline: undefined # Boolean
  }

  components: {
    formCheckbox: RactiveEditFormCheckbox
  , formDropdown: RactiveEditFormDropdown
  , formVariable: RactiveEditFormVariable
  , spacer:       RactiveEditFormSpacer
  }

  twoway: false

  validate: (form) ->

    boxtype  = form.boxtype.value
    variable = form.variable.value

    weg = WidgetEventGenerators

    out =
      {
        triggers: {
          variable: [weg.recompile, weg.rename]
        }
      , values: {
          boxedValue: { type: boxtype }
        ,    display: variable
        ,   variable: variable.toLowerCase()
        }
      }

    if boxtype isnt @get('boxtype')

      default_ =
        switch boxtype
          when "Color"  then 0 # Color number for black
          when "Number" then 0
          else               ""

      boxedValue.currentValue = default_
      boxedValue.value        = default_

    if boxtype isnt "Color" and boxtype isnt "Number"
      boxedValue.multiline = form.multiline.checked

    out

  partials: {

    title: "Input"

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      <formVariable id="{{id}}-varname" name="variable" value="{{display}}" />
      <spacer height="15px" />
      <div class="flex-row" style="align-items: center;">
        <formDropdown id="{{id}}-boxtype" name="boxtype" label="Type" selected="{{boxtype}}"
                      choices="['Number', 'String', 'Color', 'String (reporter)', 'String (commands)']"
                      disableds="['String (reporter)', 'String (commands)']" /> <!-- Disabled until `run`/`runresult` work on strings --JAB (6/8/16) -->
        <formCheckbox id="{{id}}-multiline-checkbox" isChecked={{isMultiline}} labelText="Multiline"
                      name="multiline" disabled="typeof({{isMultiline}}) == 'undefined'" />
      </div>
      <spacer height="10px" />
      """
    # coffeelint: enable=max_line_length

  }

})

window.RactiveInput = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  }

  computed: {
    hexColor: { # String
      get: ->
        try netlogoColorToHexString(@get('widget').currentValue)
        catch ex
          "#000000"
      set: (hex) ->
        color =
          try hexStringToNetlogoColor(hex)
          catch ex
            0
        @set('widget.currentValue', color)
        return
    }
  }

  components: {
    editForm: InputEditForm
  , editor:   RactiveCodeContainerMultiline
  }

  oninit: ->

    @_super()

    @on('handleKeypress', ({ original: { keyCode, target } }) ->
      if (not @get('isMultiline')) and keyCode is 13 # Enter key in single-line input
        target.blur()
        false
    )

  onrender: ->

    # Scroll to bottom on value change --JAB (8/17/16)
    @observe('widget.currentValue'
    , ->
      elem = @find('.netlogo-multiline-input')
      if elem?
        scrollToBottom = -> elem.scrollTop = elem.scrollHeight
        setTimeout(scrollToBottom, 0)
      return
    )

    return

  template:
    """
    {{>input}}
    <editForm idBasis="{{id}}" boxtype="{{widget.boxedValue.type}}" display="{{widget.display}}"
              {{# widget.boxedValue.type !== 'Color' && widget.boxedValue.type !== 'Number' }}
                isMultiline="{{widget.boxedValue.multiline}}"
              {{/}}
              />
    """

  # coffeelint: disable=max_line_length
  partials: {

    input:
      """
      <label id="{{id}}"
             on-contextmenu="@this.fire('showContextMenu', @event)"
             class="netlogo-widget netlogo-input-box netlogo-input"
             style="{{dims}}">
        <div class="netlogo-label">{{widget.variable}}</div>
        {{# widget.boxedValue.type === 'Number'}}
          <input class="netlogo-multiline-input" type="number" value="{{widget.currentValue}}" />
        {{/}}
        {{# widget.boxedValue.type === 'String'}}
          <textarea class="netlogo-multiline-input" value="{{widget.currentValue}}" on-keypress="handleKeypress"></textarea>
        {{/}}
        {{# widget.boxedValue.type === 'String (reporter)' || widget.boxedValue.type === 'String (commands)' }}
          <editor extraClasses="['netlogo-multiline-input']" id="{{id}}-code" injectedConfig="{ scrollbarStyle: 'null' }" style="height: 50%;" code="{{widget.currentValue}}" />
        {{/}}
        {{# widget.boxedValue.type === 'Color'}}
          <input class="netlogo-multiline-input" style="margin: 0; width: 100%;" type="color" value="{{hexColor}}" />
        {{/}}
      </label>
      """

  }
  # coffeelint: enable=max_line_length

})

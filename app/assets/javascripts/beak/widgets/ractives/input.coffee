InputEditForm = EditForm.extend({

  data: -> {
    boxtype:     undefined # String
  , display:     undefined # String
  , isMultiline: undefined # Boolean
  , value:       undefined # Any
  }

  components: {
    formCheckbox: RactiveEditFormCheckbox
  , formDropdown: RactiveEditFormDropdown
  , formVariable: RactiveEditFormVariable
  , spacer:       RactiveEditFormSpacer
  }

  twoway: false

  genProps: (form) ->

    boxtype  = form.boxtype.value
    variable = form.variable.value

    value =
      if boxtype is @get('boxtype')
        @get('value')
      else
        switch boxtype
          when "Color"  then 0 # Color number for black
          when "Number" then 0
          else               ""

    boxedValueBasis =
      if boxtype isnt "Color" and boxtype isnt "Number"
        { multiline: form.multiline.checked }
      else
        {}

    {
        boxedValue: Object.assign(boxedValueBasis, { type: boxtype, value: value })
    , currentValue: value
    ,      display: variable
    ,     variable: variable.toLowerCase()
    }

  partials: {

    title: "Input"

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      <formVariable id="{{id}}-varname" name="variable" value="{{display}}" />
      <spacer height="15px" />
      <div class="flex-row" style="align-items: center;">
        <formDropdown id="{{id}}-boxtype" name="boxtype" label="Type" selected="{{boxtype}}"
                      choices="['String', 'Number', 'Color', 'String (reporter)', 'String (commands)']" />
        <formCheckbox id="{{id}}-multiline-checkbox" isChecked={{isMultiline}} labelText="Multiline"
                      name="multiline" disabled="typeof({{isMultiline}}) === 'undefined'" />
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

  components: {
    colorInput: RactiveColorInput
  , editForm:   InputEditForm
  , editor:     RactiveCodeContainerMultiline
  }

  eventTriggers: ->
    amProvingSelf  = @findComponent('editForm').get('amProvingMyself')
    recompileEvent = if amProvingSelf then @_weg.recompileLite else @_weg.recompile
    {
      currentValue: [@_weg.updateEngineValue]
    ,     variable: [recompileEvent, @_weg.rename]
    }

  on: {

    # We get this event even when switching boxtypes (from Command/Reporter to anything else).
    # However, this is a problem for Color and Number Inputs, because the order of things is:
    #
    #   * Set new default value (`0`)
    #   * Plug it into the editor (where it converts to `"0"`)
    #   * Update the data model with this value
    #   * Throw out the editor and replace it with the proper HTML element
    #   * Oh, gosh, my number is actually a string
    #
    # The proper fix is really to get rid of the editor before stuffing the new value into it,
    # but that sounds fidgetty.  This fix is also fidgetty, but it's only fidgetty here, for Inputs;
    # other widget types are left unbothered by this. --JAB (4/16/18)
    'code-changed': (_, newValue) ->
      if @get('widget').boxedValue.type.includes("String ")
        @set('widget.currentValue', newValue)
      false

    'handle-keypress': ({ original: { keyCode, target } }) ->
      if (not @get('widget.boxedValue.multiline')) and keyCode is 13 # Enter key in single-line input
        target.blur()
        false

    render: ->

      # Scroll to bottom on value change --JAB (8/17/16)
      @observe('widget.currentValue'
      , (newValue, oldValue) =>

          @scrollToBottom(newValue)

          @validateValue(newValue, oldValue)

          return

      )

  }

  # (String) => Unit
  scrollToBottom: (newValue) ->
    elem = @find('.netlogo-multiline-input')
    if elem?
      scrollToBottom = -> elem.scrollTop = elem.scrollHeight
      setTimeout(scrollToBottom, 0)

    @findComponent('editor')?.setCode(newValue)
    return

  # (String, String|Number, String|Number) => Unit
  resetValue: (type, oldValue, defaultValue) ->
    # Make sure the oldValue is of the right type to avoid infinite reset loops -JMB November 2019
    newValue = if typeof(oldValue) isnt type then defaultValue else oldValue
    @set("widget.currentValue", newValue)
    @fire("set-global", @get("widget.variable"), newValue)

  # Without this fix if you set a string input global to a number or vice versa then NLW will not let you make further
  # code changes, as the compiler blows up when trying to parse the now-invalid input widget, which is very bad.

  # This kind of type checking should probably not be handled here.  It would be better to catch this during the
  # update of the global and to throw a simple runtime error there.  But at the moment there isn't a clean way to get
  # the input widget types for checking in the engine.

  # So this is a temporary workaround to avoid getting into the unfixable state. It should be removed once setting a
  # global defined by an input widget can't be set to avalue of the wrong type. -Jeremy B November 2019

  # (String|Number, String|Number) => Unit
  validateValue: (newValue, oldValue) ->
    inputType = @get("widget.boxedValue.type")
    valueType = typeof(newValue)

    if ([ "Color", "Number" ].includes(inputType) and valueType isnt "number")
      @resetValue("number", oldValue, 0)
      return

    if (inputType.startsWith("String") and valueType isnt "string")
      @resetValue("string", oldValue, "")
      return

    return

  minWidth:  70
  minHeight: 43

  template:
    """
    {{>editorOverlay}}
    {{>input}}
    <editForm idBasis="{{id}}" boxtype="{{widget.boxedValue.type}}" display="{{widget.display}}"
              {{# widget.boxedValue.type !== 'Color' && widget.boxedValue.type !== 'Number' }}
                isMultiline="{{widget.boxedValue.multiline}}"
              {{/}} value="{{widget.currentValue}}"
              />
    """

  # coffeelint: disable=max_line_length
  partials: {

    input:
      """
      <label id="{{id}}" class="netlogo-widget netlogo-input-box netlogo-input {{classes}}" style="{{dims}}">
        <div class="netlogo-label">{{widget.variable}}</div>
        {{# widget.boxedValue.type === 'Number'}}
          <input class="netlogo-multiline-input" type="number" value="{{widget.currentValue}}" lazy="true" {{# isEditing }}disabled{{/}} />
        {{/}}
        {{# widget.boxedValue.type === 'String'}}
          <textarea class="netlogo-multiline-input" value="{{widget.currentValue}}" on-keypress="handle-keypress" lazy="true" {{# isEditing }}disabled{{/}} ></textarea>
        {{/}}
        {{# widget.boxedValue.type === 'String (reporter)' || widget.boxedValue.type === 'String (commands)' }}
          <editor extraClasses="['netlogo-multiline-input']" id="{{id}}-code" injectedConfig="{ scrollbarStyle: 'null' }" style="height: 50%;" initialCode="{{widget.currentValue}}" isDisabled="{{isEditing}}" />
        {{/}}
        {{# widget.boxedValue.type === 'Color'}}
          <colorInput class="netlogo-multiline-input" style="margin: 0; width: 100%;" value="{{widget.currentValue}}" isEnabled="{{!isEditing}}" />
        {{/}}
      </label>
      """

  }
  # coffeelint: enable=max_line_length

})

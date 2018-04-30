SwitchEditForm = EditForm.extend({

  data: -> {
    display: undefined # String
  }

  twoway: false

  components: {
    formVariable: RactiveEditFormVariable
  }

  genProps: (form) ->
    variable = form.variable.value
    {
       display: variable
    , variable: variable.toLowerCase()
    }

  partials: {

    title: "Switch"

    widgetFields:
      """
      <formVariable id="{{id}}-varname" name="variable" value="{{display}}"/>
      """

  }

})

window.RactiveSwitch = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , resizeDirs:         ['left', 'right']
  }

  # `on` and `currentValue` should be synonymous for Switches.  It is necessary that we
  # update `on`, because that's what the widget reader looks at at compilation time in
  # order to determine the value of the Switch. --JAB (3/31/16)
  oninit: ->
    @_super()
    Object.defineProperty(@get('widget'), "on", {
      get:     -> @currentValue
      set: (x) -> @currentValue = x
    })

  components: {
    editForm: SwitchEditForm
  }

  eventTriggers: ->
    recompileEvent =
      if @findComponent('editForm').get('amProvingMyself') then @_weg.recompileLite else @_weg.recompile
    { variable: [recompileEvent, @_weg.rename] }

  minWidth:  35
  minHeight: 33

  template:
    """
    {{>editorOverlay}}
    {{>switch}}
    <editForm idBasis="{{id}}" display="{{widget.display}}" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    switch:
      """
      <label id="{{id}}" class="netlogo-widget netlogo-switcher netlogo-input {{classes}}" style="{{dims}}">
        <input type="checkbox" checked="{{ widget.currentValue }}" {{# isEditing }} disabled{{/}} />
        <span class="netlogo-label">{{ widget.display }}</span>
      </label>
      """

  }
  # coffeelint: enable=max_line_length

})

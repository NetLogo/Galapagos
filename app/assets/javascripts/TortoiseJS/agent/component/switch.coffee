SwitchEditForm = EditForm.extend({

  data: -> {
    display: undefined # String
  }

  twoway: false

  components: {
    formVariable: RactiveEditFormVariable
  }

  validate: (form) ->
    weg      = WidgetEventGenerators
    variable = form.variable.value
    {
      triggers: {
        variable: [weg.recompile, weg.rename]
      }
    , values: {
         display: variable
      , variable: variable.toLowerCase()
      }
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
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).deleteAndRecompile]
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

  template:
    """
    {{>switch}}
    <editForm idBasis="{{id}}" display="{{widget.display}}" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    switch:
      """
      <label id="{{id}}"
             on-contextmenu="@this.fire('showContextMenu', @event)"
             {{ #isEditing }} draggable="true" on-drag="dragWidget" on-dragstart="startWidgetDrag" on-dragend="stopWidgetDrag" {{/}}
             class="netlogo-widget netlogo-switcher netlogo-input"
             style="{{dims}}">
        <input type="checkbox" checked="{{ widget.currentValue }}" {{# isEditing }} disabled{{/}} />
        <span class="netlogo-label">{{ widget.display }}</span>
      </label>
      """

  }
  # coffeelint: enable=max_line_length

})

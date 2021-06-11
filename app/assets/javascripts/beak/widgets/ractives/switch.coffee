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
      <formVariable id="{{id}}-varname" name="variable" label="Global variable" value="{{display}}"/>
      """

  }

})

HNWSwitchEditForm = SwitchEditForm.extend({

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
      @set('display', varName)
      return
  }

  partials: {

    widgetFields:
      """
      <div class="flex-row">
        <formDropdown id="{{id}}-varname" name="variable" label="Turtle variable"
                      choices="{{sortedBreedVars}}" selected="{{display}}" />
        <button on-click="@this.fire('add-breed-var', @this)" type="button" style="height: 30px;">Define New Variable</button>
      </div>
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
    <editForm idBasis="{{id}}" display="{{widget.display}}" breedVars="{{breedVars}}" />
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

window.RactiveHNWSwitch = RactiveSwitch.extend({
  components: {
    editForm: HNWSwitchEditForm
  }
})

import RactiveValueWidget from "./value-widget.js"
import EditForm from "./edit-form.js"
import { RactiveEditFormDropdown } from "./subcomponent/dropdown.js"
import { RactiveEditFormCheckbox } from "./subcomponent/checkbox.js"
import RactiveEditFormVariable from "./subcomponent/variable.js"

SwitchEditForm = EditForm.extend({

  data: -> {
    display: undefined # String
  , oldSize: undefined # Boolean
  }

  twoway: false

  components: {
    formVariable: RactiveEditFormVariable,
    formCheckbox: RactiveEditFormCheckbox
  }

  genProps: (form) ->
    variable = form.variable.value
    {
       display: variable
    , variable: variable.toLowerCase()
    ,  oldSize: form.oldSize.checked
    }

  partials: {

    title: "Switch"

    widgetFields:
      """
      <formVariable id="{{id}}-varname" name="variable" label="Global variable" value="{{display}}"/>
      <spacer height="15px" />
      <div class="flex-row"
           style="align-items: center; justify-content: space-between; margin-left: 4px; margin-right: 4px;">
        <formCheckbox id="{{id}}-old-size" isChecked="{{ oldSize }}" labelText="Use old widget sizing"
                    name="oldSize" />
      </div>
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
        <button on-click="@this.fire('add-breed-var', @this)"
                type="button" style="height: 30px;">Define New Variable</button>
      </div>
      """

  }

})

RactiveSwitch = RactiveValueWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  }

  widgetType: "switch"

  on: {
    'widget-keydown': ({ original: event }) ->
      if event.key in [' ', 'Enter']
        @set('internalValue', not @get('internalValue'))
        @fire('widget-value-change')
        event.preventDefault()
        false
      else
        true
  }

  # `on` and `currentValue` should be synonymous for Switches.  It is necessary that we
  # update `on`, because that's what the widget reader looks at at compilation time in
  # order to determine the value of the Switch. --Jason B. (3/31/16)
  observe: {
    'widget.on': (isOn, wasOn) ->
      if (isOn isnt wasOn)
        @set('internalValue', isOn)
        @fire('widget-value-change')
      return

    'widget.currentValue': (isOn) ->
      @set('widget.on', isOn)
      return
  }

  components: {
    editForm: SwitchEditForm
  }

  eventTriggers: ->
    { variable: [@_weg.recompile, @_weg.rename] }

  minWidth:  35
  minHeight: 33

  template:
    """
    {{>editorOverlay}}
    {{>switch}}
    <editForm idBasis="{{id}}" display="{{widget.display}}" breedVars="{{breedVars}}" oldSize="{{widget.oldSize}}" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    switch:
      """
      <label id="{{id}}" class="netlogo-widget netlogo-switcher netlogo-input {{#widget.oldSize}}old-size{{/}} {{classes}}" style="{{dims}}"
        role="switch" aria-checked="{{ internalValue }}" tabindex="0" on-keydown="widget-keydown" {{attrs}}>
        <input type="checkbox" checked="{{ internalValue }}" on-change="widget-value-change" {{# isEditing }} disabled{{/}} hidden />
        <span class="netlogo-label">{{ widget.display }}</span>
        <div class="netlogo-switcher-element" role="presentation">
          <div class="netlogo-switcher-element-knob" ></div>
        </div>
      </label>
      """

  }
  # coffeelint: enable=max_line_length

})

RactiveHNWSwitch = RactiveSwitch.extend({
  components: {
    editForm: HNWSwitchEditForm
  }
})

export { RactiveSwitch, RactiveHNWSwitch }

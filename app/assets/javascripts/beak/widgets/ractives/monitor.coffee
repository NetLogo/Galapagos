import RactiveWidget from "./widget.js"
import EditForm from "./edit-form.js"
import { RactiveEditFormMultilineCode } from "./subcomponent/code-container.js"
import { RactiveEditFormDropdown } from "./subcomponent/dropdown.js"
import { RactiveEditFormCheckbox } from "./subcomponent/checkbox.js"
import RactiveEditFormSpacer from "./subcomponent/spacer.js"
import RactiveEditFormFontSize from "./subcomponent/font-size.js"
import { RactiveEditFormLabeledInput } from "./subcomponent/labeled-input.js"

MonitorEditForm = EditForm.extend({

  data: -> {
    display:   undefined # String
  , fontSize:  undefined # Number
  , precision: undefined # Number
  , source:    undefined # String
  , units:     undefined # String
  , oldSize:   undefined # Boolean
  }

  components: {
    formCode:     RactiveEditFormMultilineCode
  , formDropdown: RactiveEditFormDropdown
  , formFontSize: RactiveEditFormFontSize
  , formCheckbox: RactiveEditFormCheckbox
  , labeledInput: RactiveEditFormLabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  twoway: false

  # Note how we obtain the code.  We don't grab it out of the form.  The code is not given a `name`.
  # `name` is not valid on a `div`.  Our CodeMirror instances are using `div`s.  They *could* use
  # `textarea`s, but I tried that, and it just makes things harder for us.  `textarea`s can take
  # `name`s, yes, but CodeMirror only updates the true `textarea`'s value for submission when the
  # `submit` event is triggered, and we're not using the proper `submit` event (since we're using
  # Ractive's), so the `textarea` doesn't have the correct value when we get here.  It's much, much
  # more straight-forward to just go digging in the form component for its value.
  # --Jason B. (4/21/16)
  genProps: (form) ->
    fontSize = parseInt(form.fontSize.value)
    {
        display: (if form.display.value isnt "" then form.display.value else undefined)
    ,  fontSize
    ,    height: (2 * fontSize) + 38
    , precision: parseInt(form.precision.value)
    ,    source: @findComponent('formCode').findComponent('codeContainer').get('code')
    ,     units: (if form.units.value isnt "" then form.units.value else undefined)
    ,   oldSize: form.oldSize.checked
    }

  partials: {

    title: "Monitor"

    sourceForm:
      """
      <formCode id="{{id}}-source" name="source" value="{{source}}" label="Reporter" />
      """

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      {{>sourceForm}}

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center;">
        <labeledInput id="{{id}}-display" labelStr="Display name:" name="display" class="widget-edit-inputbox" type="text" value="{{display}}" />
      </div>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center; justify-content: space-between;">

        <div class="flex-row" style="width: 50%; align-items: center;">
          <label for="{{id}}">Decimal places: </label>
          <input  id="{{id}}" name="precision" placeholder="(Required)"
                  class="widget-edit-inputbox" style="width: 70px;"
                  type="number" value="{{precision}}" min=-30 max=17 step=1 required />
        </div>

        <labeledInput id="{{id}}-units" labelStr="Units:" labelStyle="margin-left: 10px;" name="units" type="text" value="{{units}}"
                      style="flex-grow: 1; padding: 4px;" />
      </div>

      <spacer height="15px" />

      <formFontSize id="{{id}}-font-size" name="fontSize" value="{{fontSize}}"/>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center; justify-content: space-between; margin-left: 4px; margin-right: 4px;">
        <formCheckbox id="{{id}}-old-size" isChecked="{{ oldSize }}" labelText="Use old widget sizing"
                    name="oldSize" />
      </div>
      """
    # coffeelint: enable=max_line_length

  }

})

HNWMonitorEditForm = MonitorEditForm.extend({

  computed: {
    reporterChoices: {
      get: ->

        { globalVars, myVars, procedures } = @get('metadata')

        globalsNames = globalVars.map((g) -> g.name)

        reporterNames =
          procedures.filter(
            (p) ->
              p.isReporter and
              p.argCount is 0 and
              (p.isUseableByObserver or p.isUseableByTurtles)
          ).map(
            (p) -> p.name
          )

        [].concat(globalsNames, myVars, reporterNames).sort()

      set: ((->))
    }
  }

  genProps: (form) ->

    source = form.source.value

    reporterStyle =
      if source is ""
        "turtle-procedure"
      else
        { globalVars, myVars, procedures } = @get('metadata')
        proc = procedures.find((p) -> p.name is source)
        if proc?
          if proc.isUseableByTurtles
            "turtle-procedure"
          else
            "procedure"
        else if myVars.includes(source)
          "turtle-var"
        else if globalVars.includes(source)
          "global-var"
        else
          throw Error("Wat?")

    fontSize = 10

    {
            display: (if form.display.value isnt "" then form.display.value else source)
    ,      fontSize
    ,        height: (2 * fontSize) + 23
    ,     precision: parseInt(form.precision.value)
    , reporterStyle
    ,        source
    ,       oldSize: form.oldSize.checked
    }

  partials: {

    sourceForm:
      """
      <formDropdown id="{{id}}-source" name="source" selected="{{source}}"
                    choices="{{reporterChoices}}" label="Reporter" />
      """

  }

})

RactiveMonitor = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , errorClass:         undefined # String
  }

  components: {
    editForm: MonitorEditForm
  }

  eventTriggers: ->
    { source: [@_weg.recompile] }

  # (Widget) => Array[Any]
  getExtraNotificationArgs: () ->
    widget = @get('widget')
    [widget.display, widget.source]

  minWidth:  20
  minHeight: 45

  template:
    """
    {{>editorOverlay}}
    {{>monitor}}
    <editForm idBasis="{{id}}" display="{{widget.display}}" fontSize="{{widget.fontSize}}"
              precision="{{widget.precision}}" source="{{widget.source}}" metadata="{{metadata}}"
              units={{widget.units}} oldSize="{{widget.oldSize}}" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    monitor:
      """
      <div id="{{id}}" class="netlogo-widget netlogo-monitor netlogo-output {{#widget.oldSize}}old-size{{/}} {{classes}}"
           style="{{dims}} font-size: {{widget.fontSize}}px;" {{attrs}} on-copy='copy-current-value'>
        <label class="netlogo-label {{errorClass}}" on-click="['show-widget-errors', widget]">
          {{widget.display || widget.source}}
        </label>
        <div class="flex-row" style="align-items: baseline; justify-content: center; gap: 0.25rem;">
          <output class="netlogo-value">{{widget.currentValue}}</output>
          {{#widget.units}}
            <span class="netlogo-units">{{widget.units}}</span>
          {{/}}
        </div>
      </div>
      """

  }
  # coffeelint: enable=max_line_length

})

RactiveHNWMonitor = RactiveMonitor.extend({
  components: {
    editForm: HNWMonitorEditForm
  }
})

export { RactiveMonitor, RactiveHNWMonitor }

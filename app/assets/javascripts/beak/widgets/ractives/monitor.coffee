import RactiveWidget from "./widget.js"
import EditForm from "./edit-form.js"
import { RactiveEditFormMultilineCode } from "./subcomponent/code-container.js"
import { RactiveEditFormDropdown } from "./subcomponent/dropdown.js"
import RactiveEditFormSpacer from "./subcomponent/spacer.js"
import RactiveEditFormFontSize from "./subcomponent/font-size.js"
import { RactiveEditFormLabeledInput } from "./subcomponent/labeled-input.js"

MonitorEditForm = EditForm.extend({

  data: -> {
    display:   undefined # String
  , fontSize:  undefined # Number
  , precision: undefined # Number
  , source:    undefined # String
  }

  components: {
    formCode:     RactiveEditFormMultilineCode
  , formDropdown: RactiveEditFormDropdown
  , formFontSize: RactiveEditFormFontSize
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
    ,    bottom: @parent.get('widget.top') + (2 * fontSize) + 23
    , precision: parseInt(form.precision.value)
    ,    source: @findComponent('formCode').findComponent('codeContainer').get('code')
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

        <label for="{{id}}">Decimal places: </label>
        <input  id="{{id}}" name="precision" placeholder="(Required)"
                class="widget-edit-inputbox" style="width: 70px;"
                type="number" value="{{precision}}" min=-30 max=17 step=1 required />
        <spacer width="50px" />
        <formFontSize id="{{id}}-font-size" name="fontSize" value="{{fontSize}}"/>

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
    ,        bottom: @parent.get('widget.top') + (2 * fontSize) + 23
    ,     precision: parseInt(form.precision.value)
    , reporterStyle
    ,        source
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
  , resizeDirs:         ['left', 'right']
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
              precision="{{widget.precision}}" source="{{widget.source}}" metadata="{{metadata}}" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    monitor:
      """
      <div id="{{id}}" class="netlogo-widget netlogo-monitor netlogo-output {{classes}}"
           style="{{dims}} font-size: {{widget.fontSize}}px;">
        <label class="netlogo-label {{errorClass}}" on-click="['show-widget-errors', widget]">
          {{widget.display || widget.source}}
        </label>
        <output class="netlogo-value">{{widget.currentValue}}</output>
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

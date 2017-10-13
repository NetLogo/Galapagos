MonitorEditForm = EditForm.extend({

  data: -> {
    display:   undefined # String
  , fontSize:  undefined # Number
  , precision: undefined # Number
  , source:    undefined # String
  }

  components: {
    formCode:     RactiveEditFormCodeContainer
  , formFontSize: RactiveEditFormFontSize
  , spacer:       RactiveEditFormSpacer
  }

  twoway: false

  # Note how we obtain the code.  We don't grab it out of the form.  The code is not given a `name`.
  # `name` is not valid on a `div`.  Our CodeMirror instances are using `div`s.  They *could* use
  # `textarea`s, but I tried that, and it just makes things harder for us.  `textarea`s can take
  # `name`s, yes, but CodeMirror only updates the true `textarea`'s value for submission when the
  # `submit` event is triggered, and we're not using the proper `submit` event (since we're using
  # Ractive's), so the `textarea` doesn't have the correct value when we get here.  It's much, much
  # more straight-forward to just go digging in the form component for its value. --JAB (4/21/16)
  validate: (form) ->
    {
      triggers: {
        source: [WidgetEventGenerators.recompile]
      }
    , values: {
          display: (if form.display.value isnt "" then form.display.value else undefined)
      ,  fontSize: parseInt(form.fontSize.value)
      , precision: parseInt(form.precision.value)
      ,    source: @findComponent('formCode').findComponent('codeContainer').get('code')
      }
    }

  partials: {

    title: "Monitor"

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      <formCode id="{{id}}-source" name="source" value="{{source}}" label="Reporter" />

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center;">
        <label for="{{id}}-display">Display name:</label>
        <input  id="{{id}}-display" name="display" type="text" value="{{display}}"
                style="flex-grow: 1; font-size: 20px; height: 26px; margin-left: 10px; padding: 4px;" />
      </div>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center; justify-content: space-between;">

        <label for="{{id}}">Decimal places: </label>
        <input  id="{{id}}" name="precision" placeholder="(Required)"
                style="font-size: 20px; height: 28px; padding: 2px;"
                type="number" value="{{precision}}" min=-30 max=17 step=1 required />
        <spacer width="50px" />
        <formFontSize id="{{id}}-font-size" name="fontSize" value="{{fontSize}}"/>

      </div>
      """
    # coffeelint: enable=max_line_length

  }

})

window.RactiveMonitor = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
    errorClass:         undefined # String
  }

  components: {
    editForm: MonitorEditForm
  }

  template:
    """
    {{>monitor}}
    <editForm idBasis="{{id}}" display="{{widget.display}}" fontSize="{{widget.fontSize}}"
              precision="{{widget.precision}}" source="{{widget.source}}" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    monitor:
      """
      <div id="{{id}}"
           on-contextmenu="@this.fire('showContextMenu', @event)"
           class="netlogo-widget netlogo-monitor netlogo-output"
           style="{{dims}} font-size: {{widget.fontSize}}px;">
        <label class="netlogo-label {{errorClass}}" on-click=\"showErrors\">{{widget.display || widget.source}}</label>
        <output class="netlogo-value">{{widget.currentValue}}</output>
      </div>
      """

  }
  # coffeelint: enable=max_line_length

})

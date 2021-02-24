import RactiveWidget from "./widget.js"
import EditForm from "./edit-form.js"
import RactivePrintArea from "./subcomponent/print-area.js"
import RactiveEditFormFontSize from "./subcomponent/font-size.js"

OutputEditForm = EditForm.extend({

  data: -> {
    fontSize: undefined # Number
  }

  twoway: false

  components: {
    formFontSize: RactiveEditFormFontSize
  }

  genProps: (form) ->
    { fontSize: parseInt(form.fontSize.value) }

  partials: {

    title: "Output"

    widgetFields:
      """
      <formFontSize id="{{id}}-font-size" name="fontSize" style="margin-left: 0;" value="{{fontSize}}"/>
      """

  }

})

RactiveOutputArea = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , text:               undefined # String
  }

  components: {
    editForm:  OutputEditForm
  , printArea: RactivePrintArea
  }

  eventTriggers: ->
    {}

  # String -> Unit
  appendText: (str) ->
    @set('text', @get('text') + str)
    return

  setText: (str) ->
    @set('text', str)
    return

  minWidth:  15
  minHeight: 25

  template:
    """
    {{>editorOverlay}}
    {{>output}}
    <editForm idBasis="{{id}}" fontSize="{{widget.fontSize}}" style="width: 285px;" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    output:
      """
      <div id="{{id}}" class="netlogo-widget netlogo-output netlogo-output-widget {{classes}}" style="{{dims}}">
        <printArea id="{{id}}-print-area" fontSize="{{widget.fontSize}}" output="{{text}}" />
      </div>
      """

  }
  # coffeelint: enable=max_line_length

})

export default RactiveOutputArea

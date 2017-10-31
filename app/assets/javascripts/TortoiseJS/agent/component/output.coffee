OutputEditForm = EditForm.extend({

  data: -> {
    fontSize: undefined # Number
  }

  twoway: false

  components: {
    formFontSize: RactiveEditFormFontSize
  }

  validate: (form) ->
    { values: { fontSize: parseInt(form.fontSize.value) } }

  partials: {

    title: "Output"

    widgetFields:
      """
      <formFontSize id="{{id}}-font-size" name="fontSize" value="{{fontSize}}"/>
      """

  }

})

window.RactiveOutputArea = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , text:               undefined # String
  }

  components: {
    editForm:  OutputEditForm
  , printArea: RactivePrintArea
  }

  # String -> Unit
  appendText: (str) ->
    @set('text', @get('text') + str)
    return

  setText: (str) ->
    @set('text', str)
    return

  template:
    """
    {{>output}}
    <editForm idBasis="{{id}}" fontSize="{{widget.fontSize}}" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    output:
      """
      <div id="{{id}}" on-contextmenu="@this.fire('showContextMenu', @event)"
           class="netlogo-widget netlogo-output netlogo-output-widget" style="{{dims}}">
        <printArea id="{{id}}-print-area" fontSize="{{widget.fontSize}}" output="{{text}}" />
      </div>
      """

  }
  # coffeelint: enable=max_line_length

})

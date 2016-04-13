OutputEditForm = EditForm.extend({

  data: -> {
    fontSize: undefined # Number
  }

  isolated: true

  components: {
    formFontSize: RactiveEditFormFontSize
  }

  validate: (form) ->
    { fontSize: parseInt(form.fontSize.value) }

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
    text: undefined # String
  }

  isolated: true

  components: {
    editForm:  OutputEditForm
  , printArea: RactivePrintArea
  }

  template:
    """
    {{>output}}
    {{>contextMenu}}
    <editForm idBasis="{{id}}" fontSize="{{widget.fontSize}}" twoway="false"/>
    """

  # coffeelint: disable=max_line_length
  partials: {

    output:
      """
      <div id="{{id}}" on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
           class="netlogo-widget netlogo-output netlogo-output-widget" style="{{dims}}">
        <printArea id="{{id}}-print-area" fontSize="{{widget.fontSize}}" output="{{text}}" />
      </div>
      """

    contextMenu:
      """
      <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
        <ul class="context-menu-list">
          <li class="context-menu-item" on-click="editWidget">Edit</li>
          <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
        </ul>
      </div>
      """

  }
  # coffeelint: enable=max_line_length

})

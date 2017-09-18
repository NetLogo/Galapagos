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
    text: undefined # String
  }

  components: {
    editForm:  OutputEditForm
  , printArea: RactivePrintArea
  }

  # String -> Unit
  appendText: (str) ->
    @set('text', @get('text') + str)
    return

  template:
    """
    {{>output}}
    {{>contextMenu}}
    <editForm idBasis="{{id}}" fontSize="{{widget.fontSize}}" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    output:
      """
      <div id="{{id}}" on-contextmenu="@this.fire('showContextMenu', @event, id + '-context-menu')"
           class="netlogo-widget netlogo-output netlogo-output-widget" style="{{dims}}">
        <printArea id="{{id}}-print-area" fontSize="{{widget.fontSize}}" output="{{text}}" />
      </div>
      """

    contextMenu:
      """
      <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
        <ul class="context-menu-list">
          <li class="context-menu-item" on-click="editWidget">Edit</li>
          <li class="context-menu-item" on-click="@this.fire('deleteWidget', id, id + '-context-menu', widget.id)">Delete</li>
        </ul>
      </div>
      """

  }
  # coffeelint: enable=max_line_length

})

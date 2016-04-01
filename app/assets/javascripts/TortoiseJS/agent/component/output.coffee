OutputEditForm = EditForm.extend({

  data: {
    fontSize: undefined # Number
  }

  isolated: true

  validate: (form) ->
    { fontSize: form.fontSize.value }

  partials: {

    title: "Output"

    widgetFields:
      """
      <label for="{{id}}-font-size">Font Size: </label>
      <input id="{{id}}-font-size" class="widget-edit-text-size" name="fontSize" placeholder="(Required)"
             type="number" value="{{fontSize}}" autofocus min=1 max=128 required />
      """

  }

})

window.RactiveOutputArea = RactiveWidget.extend({

  data: -> {
    output: undefined # String
  }

  isolated: true

  components: {
    editForm:  OutputEditForm
  , printArea: RactivePrintArea
  }

  template:
    """
    <div id="{{id}}"
         on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
         class="netlogo-widget netlogo-output netlogo-output-widget" style="{{dims}}">
      <printArea id="{{id}}-print-area" fontSize="{{widget.fontSize}}" output="{{output}}" />
    </div>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item" on-click="editWidget">Edit</li>
        <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
      </ul>
    </div>
    <editForm idBasis="{{id}}" fontSize="{{widget.fontSize}}" twoway="false"/>
    """

})

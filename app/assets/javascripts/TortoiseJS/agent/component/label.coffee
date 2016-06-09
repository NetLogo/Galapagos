LabelEditForm = EditForm.extend({

  data: -> {
    color:       undefined # String
  , fontSize:    undefined # Number
  , text:        undefined # String
  , transparent: undefined # Boolean
  }

  isolated: true

  twoway: false

  components: {
    formCheckbox: RactiveEditFormCheckbox
  , formFontSize: RactiveEditFormFontSize
  , spacer:       RactiveEditFormSpacer
  }

  validate: (form) ->
    color = window.hexStringToNetlogoColor(form.color.value)
    { color, display: form.text.value, fontSize: parseInt(form.fontSize.value)
    , transparent: form.transparent.checked }

  partials: {

    title: "Note"

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      <label for="{{id}}-text">Text</label><br>
      <textarea id="{{id}}-text" class="widget-edit-textbox"
                name="text" placeholder="Enter note text here..."
                value="{{text}}" autofocus></textarea>

      <spacer height="20px" />

      <div class="flex-row" style="align-items: center;">
        <div style="width: 48%;">
          <formFontSize id="{{id}}-font-size" name="fontSize" value="{{fontSize}}"/>
        </div>
        <spacer width="4%" />
        <div style="width: 48%;">
          <label for="{{id}}-text-color">Text color:</label>
          <input id="{{id}}-text-color" class="widget-edit-color-picker" name="color"
                 type="color" value="{{color}}" />
        </div>
      </div>

      <spacer height="15px" />

      <formCheckbox id="{{id}}-transparent-checkbox" isChecked={{transparent}} labelText="Transparent background" name="transparent" />
      """
    # coffeelint: enable=max_line_length

  }

})

window.RactiveLabel = RactiveWidget.extend({

  data: -> {
    convertColor: netlogoColorToCSS
  }

  isolated: true

  components: {
    editForm: LabelEditForm
  }

  computed: {
    hexColor: ->
      window.netlogoColorToHexString(@get('widget').color)
  }

  template:
    """
    {{>label}}
    {{>contextMenu}}
    {{>form}}
    """

  # coffeelint: disable=max_line_length
  partials: {

    # Note that ">{{ display }}</pre>" thing is necessary. Since <pre> formats
    # text exactly as it appears, an extra space between the ">" and the
    # "{{ display }}" would result in an actual newline in the widget.
    # BCH 7/28/2015
    label:
      """
      <pre id="{{id}}"
           on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
           class="netlogo-widget netlogo-text-box"
           style="{{dims}} font-size: {{widget.fontSize}}px; color: {{ convertColor(widget.color) }}; {{# widget.transparent}}background: transparent;{{/}}"
           >{{ widget.display }}</pre>
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

    form:
      """
      <editForm idBasis="{{id}}" color="{{hexColor}}"
                fontSize="{{widget.fontSize}}" text="{{widget.display}}"
                transparent="{{widget.transparent}}" />
      """

  }
  # coffeelint: enable=max_line_length

})

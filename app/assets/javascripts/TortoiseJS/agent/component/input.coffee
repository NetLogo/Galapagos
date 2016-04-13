InputEditForm = EditForm.extend({

  data: -> {
    boxtype:     undefined # String
  , display:     undefined # String
  , isMultiline: undefined # Boolean
  }

  components: {
    formCheckbox: RactiveEditFormCheckbox
  , formDropdown: RactiveEditFormDropdown
  , formVariable: RactiveEditFormVariable
  , spacer:       RactiveEditFormSpacer
  }

  isolated: true

  twoway: false

  validate: (form) ->

    boxtype = form.boxtype.value
    varName = form.varName.value
    out = { boxtype: boxtype, display: varName, multiline: form.multiline.checked, varName: varName.toLowerCase() }

    if boxtype isnt @get('boxtype')
      default_ =
        switch boxtype
          when "Color"  then 0 # Color number for black
          when "Number" then 0
          else               ""
      out.currentValue = default_
      out.value        = default_

    out

  partials: {

    title: "Input"

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      <formVariable id="{{id}}-varname" name="varName" value="{{display}}" />
      <spacer height="15px" />
      <div style="display: flex; align-items: center;">
        <formDropdown id="{{id}}-boxtype" choices="['Number', 'String', 'Color', 'String (reporter)', 'String (commands)']" label="Type" selected="{{boxtype}}" />
        <formCheckbox id="{{id}}-multiline-checkbox" isChecked={{isMultiline}} labelText="Multiline" name="multiline" />
      </div>
      <spacer height="10px" />
      """
    # coffeelint: enable=max_line_length

  }

})

window.RactiveInput = RactiveWidget.extend({

  isolated: true

  computed: {
    hexColor: { # String
      get: ->
        try netlogoColorToHexString(@get('widget').currentValue)
        catch ex
          "#000000"
      set: (hex) ->
        color =
          try hexStringToNetlogoColor(hex)
          catch ex
            0
        @set('widget.currentValue', color)
        return
    }
  }

  components: {
    editForm: InputEditForm
  }

  template:
    """
    {{>input}}
    {{>contextMenu}}
    <editForm idBasis="{{id}}" boxtype="{{widget.boxtype}}"
              display="{{widget.display}}" isMultiline="{{widget.multiline}}" />
    """

  # coffeelint: disable=max_line_length
  partials: {

    input:
      """
      <label id="{{id}}"
             on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
             class="netlogo-widget netlogo-input-box netlogo-input"
             style="{{dims}}">
        <div class="netlogo-label">{{widget.varName}}</div>
        {{# widget.boxtype === 'Number'}}<input type="number" value="{{widget.currentValue}}" />{{/}}
        {{# widget.boxtype === 'String'}}
          {{#if widget.multiline === false}}
            <input type="text" value="{{widget.currentValue}}" />
          {{else}}
            <textarea class="netlogo-multiline-input" value="{{widget.currentValue}}"></textarea>
          {{/if}}
        {{/}}
        {{# widget.boxtype === 'String (reporter)'}}<input type="text" value="{{widget.currentValue}}" />{{/}}
        {{# widget.boxtype === 'String (commands)'}}<input type="text" value="{{widget.currentValue}}" />{{/}}
        <!-- TODO: Fix color input. It'd be nice to use html5s color input. -->
        {{# widget.boxtype === 'Color'}}<input type="color" value="{{hexColor}}" />{{/}}
      </label>
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

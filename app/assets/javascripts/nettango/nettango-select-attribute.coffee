window.RactiveNetTangoSelectAttribute = Ractive.extend({

  data: () -> {
    attribute: undefined, # NetTangoSelectAttribute
    optionTemplate:
      """
      <div class="flex-row ntb-form-row">
        <input class="widget-edit-text widget-edit-input ntb-input" type="text" value="{{ actual }}" />
        <input class="widget-edit-text widget-edit-input ntb-input" type="text" value="{{ display }}" />
        {{> delete-button }}
      </div>
      """
    createOption:
      () -> { actual: "10" }
  }

  on: {

    'complete': (_) ->
      attribute = @get("attribute")
      if (not attribute.values?)
        @set("attribute.values", [])
      return

  }

  components: {
    arrayView:    RactiveArrayView
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <arrayView
      id="select-{{ id }}-options"
      itemTemplate="{{ optionTemplate }}"
      items="{{ attribute.values }}"
      itemType="Option"
      itemTypePlural="Options"
      createItem="{{ createOption }}"
      viewClass="ntb-options"
      />
    """
    # coffeelint: enable=max_line_length

})

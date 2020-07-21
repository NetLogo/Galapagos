window.RactiveSelectAttribute = Ractive.extend({

  data: () -> {
    attribute: undefined, # NetTangoSelectAttribute

    optionTemplate:
      """
      <input class="widget-edit-text widget-edit-input ntb-input" type="text" value="{{ actual }}" />
      <input class="widget-edit-text widget-edit-input ntb-input" type="text" value="{{ display }}" />
      <div class="ntb-option-delete">{{> delete-button }}</div>
      """

    headerTemplate:
      """
      <div class="ntb-option-header">Actual Value</div>
      <div class="ntb-option-header">Display Value</div>
      <div />
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
    arrayView: RactiveArrayView
    dropdown:  RactiveTwoWayDropdown
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="flex-row ntb-form-row">

      <dropdown id="{{ id }}-quoted" name="{{ attribute.quoteValues }}" selected="{{ attribute.quoteValues }}" label="Quote values in code" divClass="ntb-flex-column"
      choices="{{ [ "smart-quote", "always-quote", "never-quote" ] }}" />

      <div class="ntb-flex-column" />

    </div>

    <arrayView
      id="select-{{ id }}-options"
      itemTemplate="{{ optionTemplate }}"
      items="{{ attribute.values }}"
      itemType="Option"
      itemTypePlural="Options"
      createItem="{{ createOption }}"
      viewClass="ntb-options"
      itemsWrapperClass="ntb-options-wrapper"
      headerTemplate="{{ headerTemplate }}"
      />
    """
    # coffeelint: enable=max_line_length

})

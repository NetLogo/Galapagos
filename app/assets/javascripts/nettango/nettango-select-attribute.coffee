window.RactiveNetTangoSelectAttribute = Ractive.extend({

  data: () -> {
    attribute: undefined, # NetTangoSelectAttribute
  }

  on: {

    'complete': (_) ->
      attribute = @get("attribute")
      if (not attribute.values?)
        attribute.values = []
      return

    'ntb-add-select-option': (_) ->
      @push("attribute.values", { actual: "10" })
      return

    'ntb-remove-select-option': (_, index) ->
      @splice("attribute.values", index, 1)
      return

  }

  components: {
    labeledInput: RactiveTwoWayLabeledInput
    dropdown:     RactiveTwoWayDropdown
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="flex-column" >
      <div class="flex-row ntb-form-row">
        <label>Options</label>
        <button class="ntb-button" type="button" on-click="ntb-add-select-option">Add Option</button>
      </div>
      {{#attribute.values:number }}
      <div class="flex-row ntb-form-row">
        <button class="ntb-button" type="button" on-click="[ 'ntb-remove-select-option', number ]">Remove Option</button>
        <input class="widget-edit-text widget-edit-input" type="text" value="{{ actual }}" />
        <input class="widget-edit-text widget-edit-input" type="text" value="{{ display }}" />
      </div>
      {{/attribute.values }}
    </div>
    """
    # coffeelint: enable=max_line_length

})

import { RactiveTwoWayDropdown } from "/beak/widgets/ractives/subcomponent/dropdown.js"
import RactiveArrayView from "./array-view.js"

partials = {

  headerTemplate:
    """
    <div class="ntb-option-header">Actual Value</div>
    <div class="ntb-option-header">Display Value</div>
    <div />
    """

  itemTemplate:
    """
    <input class="widget-edit-text widget-edit-input ntb-input" type="text" value="{{ actual }}" dir="auto" />
    <input class="widget-edit-text widget-edit-input ntb-input" type="text" value="{{ display }}" dir="auto" />
    <div class="ntb-option-delete">{{> deleteButton }}</div>
    """

}

RactiveSelectAttribute = Ractive.extend({

  data: () -> {
    attribute: undefined, # NetTangoSelectAttribute
    elementId: undefined, # String
    quoteOptions: undefined # Array[String]

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
    arrayView: RactiveArrayView(partials)
    dropdown:  RactiveTwoWayDropdown
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="flex-row ntb-form-row">

      <dropdown id="{{ elementId }}-quoted" name="{{ attribute.quoteValues }}" selected="{{ attribute.quoteValues }}" label="Quote values in code" divClass="ntb-flex-column"
      choices="{{ quoteOptions }}" />

      <div class="ntb-flex-column" />

    </div>

    <arrayView
      arrayViewId="select-{{ elementId }}-options"
      items="{{ attribute.values }}"
      itemType="Option"
      itemTypePlural="Options"
      createItem="{{ createOption }}"
      viewClass="ntb-options"
      itemsWrapperClass="ntb-options-wrapper"
      showAtStart={{ attribute.values.length > 0 }}
      />
    """
    # coffeelint: enable=max_line_length

})

export default RactiveSelectAttribute

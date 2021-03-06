import RactiveAttribute from "./attribute.js"
import RactiveArrayView from "./array-view.js"

partials = {

  itemTemplate:
    """
    <fieldset class="ntb-attribute">
      <legend class="widget-edit-legend">
        {{ itemType }} {{ number }} {{> deleteButton }}
      </legend>
      <div class="flex-column">
        <attribute
          id="{{ number }}"
          attribute="{{ this }}"
          attributeType="{{ itemType }}"
          codeFormat="{{ codeFormat }}"
          />
      </div>
    </fieldset>
    """

}

RactiveAttributes = Ractive.extend({

  data: () -> {
    singular:   undefined # String
    plural:     undefined # String
    blockId:    undefined # Int
    attributes: []        # Array[NetTangoAttribute]
    codeFormat: ""        # String

    createAttribute:
      (type) -> (number) -> { name: "#{type} #{number}", type: 'int', unit: undefined, def: 10 }

  }

  computed: {

    attributesId: () ->
      blockId = @get("blockId")
      plural  = @get("plural").toLowerCase()
      "block-#{blockId}-#{plural}"

  }

  components: {
    arrayView: RactiveArrayView(partials, { attribute: RactiveAttribute })
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <arrayView
      arrayViewId="{{ attributesId }}"
      items="{{ attributes }}"
      itemType="{{ singular }}"
      itemTypePlural="{{ plural }}"
      createItem="{{ createAttribute(singular) }}"
      viewClass="ntb-block-array"
      codeFormat="{{ codeFormat }}"
      showAtStart="{{ attributes.length > 0 }}"
      />
    """
    # coffeelint: enable=max_line_length
})

export default RactiveAttributes

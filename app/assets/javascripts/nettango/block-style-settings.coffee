window.RactiveBlockStyleSettings = RactiveToggle.extend({

  data: () -> {
    title:         "Block Styles" # String
    styleId:       undefined      # String
    styleSettings: undefined      # { blockColor, textColor, borderColor, fontWeight, fontSize, fontFace }
    showClear:     true           # Boolean
  }

  on: {
    '*.ntb-color-changed': ({ node: { name } }, value) ->
      @set("styleSettings.#{name}", value)
      return
  }

  components: { labeledInput: RactiveTwoWayLabeledInput }

  partials: {

    titleTemplate:
      """
      {{ title }}

      {{# showClear }}
      <button class="ntb-button" type="button" on-click="ntb-clear-styles">Clear Styles</button>
      {{/ showClear }}
      """

    contentTemplate:
      """
      {{# styleSettings }}

      <div class="flex-row ntb-form-row">

        <labeledInput
          id="{{ styleId }}-block-color"
          name="blockColor"
          type="color"
          value="{{ blockColor ? blockColor : "#000000" }}"
          labelStr="Block color"
          divClass="ntb-flex-column"
          class="ntb-input"
          onChange="ntb-color-changed"
          />

        <labeledInput
          id="{{ styleId }}-text-color"
          name="textColor"
          type="color"
          value="{{ textColor ? textColor : "#000000" }}"
          labelStr="Text color"
          divClass="ntb-flex-column"
          class="ntb-input"
          onChange="ntb-color-changed"
          />

        <labeledInput
          id="{{ styleId }}-border-color"
          name="borderColor"
          type="color"
          value="{{ borderColor ? borderColor : "#000000" }}"
          labelStr="Border color"
          divClass="ntb-flex-column"
          class="ntb-input"
          onChange="ntb-color-changed"
          />

      </div>

      <div class="flex-row ntb-form-row">

        <labeledInput
          id="{{ styleId }}-f-weight"
          name="font-weight"
          type="number"
          value="{{ fontWeight }}"
          labelStr="Font weight"
          divClass="ntb-flex-column"
          class="ntb-input" />

        <labeledInput
          id="{{ styleId }}-f-size"
          name="font-size"
          type="number"
          value="{{ fontSize }}"
          labelStr="Font size"
          divClass="ntb-flex-column"
          class="ntb-input"
          />

        <labeledInput
          id="{{ styleId }}-f-face"
          name="font-face"
          type="text"
          value="{{ fontFace }}"
          labelStr="Typeface"
          divClass="ntb-flex-column"
          class="ntb-input"
          />

      </div>

      {{/ styleSettings }}
      """

  }

})

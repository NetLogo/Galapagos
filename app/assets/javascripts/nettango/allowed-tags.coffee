window.RactiveAllowedTags = Ractive.extend({

  data: () -> {
    allowedTags: { type: 'unrestricted' } # NetTangoAllowedTags
    knownTags:   []                       # Array[String]
  }

  components: {
    dropdown: RactiveTwoWayDropdown
    tags:     RactiveTags
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="flex-column">
      {{# allowedTags }}

      <dropdown
        label="Which blocks are allowed to be added to this clause?"
        divClass="ntb-flex-column"
        selected="{{ type }}"
        choices={{ [
          { value: 'unrestricted', text: 'Allow all blocks' }
        , { value: 'any-of',       text: 'Allow blocks with any of the chosen tags' }
        , { value: 'inherit',      text: 'Allow the same blocks the container would allow when this block is added to another' }
        ] }}
        changeEvent="ntb-allowed-tags-changed"
        />

      {{# type === 'any-of' }}

      <tags
        tags={{ tags }}
        knownTags={{ knownTags }}
        />

      {{/ type }}

      {{/ allowedTags }}

    </div>
    """
    # coffeelint: enable=max_line_length

})

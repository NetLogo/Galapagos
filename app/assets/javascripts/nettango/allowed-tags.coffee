defaultChoices = [
  { value: 'unrestricted', text: 'Allow all blocks' }
, { value: 'any-of',       text: 'Allow blocks with at least one of the chosen tags' }
]

clauseChoice = {
  value: 'inherit', text: 'Allow the same blocks the container would allow when this block is added to another'
}

getChoices = (blockType) ->
  choices = defaultChoices.slice()
  if blockType is 'clause'
    choices.push(clauseChoice)
  choices

window.RactiveAllowedTags = Ractive.extend({

  data: () -> {
    allowedTags: { type: 'unrestricted' } # NetTangoAllowedTags
    knownTags:   []                       # Array[String]
  }

  computed: {

    choices: () ->
      blockType = @get('blockType')
      getChoices(blockType)

    blockTypeText: () ->
      blockType = @get('blockType')
      if blockType is 'starter'
        'chain starter'
      else
        'clause'
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
        label="Which blocks are allowed to be added to this {{ blockTypeText }}?"
        divClass="ntb-flex-column"
        selected="{{ type }}"
        choices={{ choices }}
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

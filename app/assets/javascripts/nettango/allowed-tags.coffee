import { RactiveTwoWayDropdown } from "/beak/widgets/ractives/subcomponent/dropdown.js"
import { RactiveTags } from "./tags.js"

defaultChoices = [
  { value: 'unrestricted', text: 'Allow all blocks' }
, { value: 'any-of',       text: 'Allow blocks with at least one of the chosen tags' }
, { value: 'none-of',      text: 'Disallow blocks that have any of the chosen tags' }
]

clauseChoice = {
  value: 'inherit', text: 'Allow the same blocks the container would allow when this block is added to a chain'
}

getChoices = (canInheritTags) ->
  choices = defaultChoices.slice()
  if canInheritTags
    choices.push(clauseChoice)
  choices

RactiveAllowedTags = Ractive.extend({

  data: () -> {
    id:             undefined                # String
    allowedTags:    { type: 'unrestricted' } # NetTangoAllowedTags
    knownTags:      []                       # Array[String]
    blockType:      'clause'                 # "starter" | "clause"
    canInheritTags: false                    # Boolean
  }

  computed: {

    choices: () ->
      canInheritTags = @get('canInheritTags')
      getChoices(canInheritTags)

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
    <div class="ntb-flex-column">
      {{# allowedTags }}

      <dropdown
        id="{{ id }}-dropdown"
        label="Which blocks are allowed to be added to this {{ blockTypeText }}?"
        divClass="ntb-flex-column"
        selected="{{ type }}"
        choices={{ choices }}
        changeEvent="ntb-allowed-tags-changed"
        />

      {{# ['any-of', 'none-of'].includes(type) }}

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

export default RactiveAllowedTags

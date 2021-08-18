import { RactiveTwoWayLabeledInput } from "/beak/widgets/ractives/subcomponent/labeled-input.js"
import { RactiveToggleTags } from "./tags.js"
import RactiveToggle from "./toggle.js"

RactiveTagGroupSettings = RactiveToggle.extend({

  data: () -> {
    tagGroup:   undefined # NetTangoTagGroup
    knownTags:  []        # String[]
    groupIndex: undefined # Int
  }

  components: {
    labeledInput: RactiveTwoWayLabeledInput
  , tagsControl:  RactiveToggleTags
  }

  partials: {

    titleTemplate:
      """
      {{ tagGroup.header }} Tag Group
      <button class="ntb-button" type="button" on-click="[ 'remove-item', groupIndex ]">Delete</button>
      """

    contentTemplate:
      """
      {{# tagGroup }}

      <div class="flex-row ntb-form-row">

        <labeledInput
          id       = "tag-group-{{ groupIndex }}-header"
          name     = "header"
          type     = "text"
          value    = {{ header }}
          labelStr = "Group Header"
          divClass = "ntb-flex-column"
          class    = "ntb-input"
          />

      </div>

      <div class="flex-row ntb-form-row">

        <tagsControl
          tags             = {{ tags }}
          knownTags        = {{ knownTags }}
          showAtStart      = true
          areProcedureTags = false
          allowNewTags     = false
          enableToggle     = false
          />

      </div>

      {{/ tagGroup }}
      """

  }

})

export default RactiveTagGroupSettings

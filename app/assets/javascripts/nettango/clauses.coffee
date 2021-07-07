import { RactiveTwoWayLabeledInput } from "/beak/widgets/ractives/subcomponent/labeled-input.js"
import RactiveAllowedTags from "./allowed-tags.js"
import RactiveArrayView from "./array-view.js"
import RactiveCodeMirror from "./code-mirror.js"

partials = {

  headerTemplate:
    """
    <div class="flex-column">
      <div class="flex-row ntb-form-row">

        <div class="ntb-flex-column">
          <label for="{{ arrayViewId }}-close">Code format to insert after all clauses</label>
          <codeMirror
            id="{{ arrayViewId }}-close"
            mode="netlogo"
            code={{ closeClauses }}
            extraClasses="['ntb-code-input']"
          />
        </div>

      </div>
    </div>
    """

  itemTemplate:
    """
    <fieldset class="ntb-attribute">
      <legend class="widget-edit-legend">
        {{ itemType }} {{ number }} {{> deleteButton }}
      </legend>
      <div class="flex-column">

        <div class="flex-row ntb-form-row">

          <labeledInput name="action" type="text" value="{{ action }}" labelStr="Display name"
            divClass="ntb-flex-column" class="ntb-input" />

          <div class="ntb-flex-column">
            <label for="{{ arrayViewId }}-{{ number }}-open">Start code format (default is `[`)</label>
            <codeMirror
              id="{{ arrayViewId }}-{{ number }}-open"
              mode="netlogo"
              code={{ open }}
              extraClasses="['ntb-code-input']"
              multilineClass="ntb-code-input-big"
            />
          </div>

          <div class="ntb-flex-column">
            <label for="{{ arrayViewId }}-{{ number }}-close">End code format (default is `]`)</label>
            <codeMirror
              id="{{ arrayViewId }}-{{ number }}-close"
              mode="netlogo"
              code={{ close }}
              extraClasses="['ntb-code-input']"
              multilineClass="ntb-code-input-big"
            />
          </div>

        </div>

        <div class="flex-row ntb-form-row">
          <allowedTags
            id="{{ arrayViewId }}-{{ number }}-allowed-tags"
            allowedTags={{ allowedTags }}
            knownTags={{ knownTags }}
            blockType="clause"
            canInheritTags={{ canInheritTags }}
            />
        </div>

      </div>
    </fieldset>
    """

}

RactiveClauses = Ractive.extend({

  data: () -> {
    blockId:        undefined # Int
    clauses:        []        # Array[NetTangoAttribute]
    closeClauses:   ""        # String
    knownTags:      []        # Array[String]
    canInheritTags: false     # Boolean

    createClause:
      (number) -> {
        open:   undefined
      , close:  undefined
      , blocks: []
      , allowedTags: { type: 'unrestricted' }
      }

  }

  components: {
    arrayView: RactiveArrayView(partials, {
      allowedTags:  RactiveAllowedTags
    , codeMirror:   RactiveCodeMirror
    , labeledInput: RactiveTwoWayLabeledInput
    })
  }

  template:
    """
    <arrayView
      arrayViewId="block-{{ blockId }}-clauses"
      items="{{ clauses }}"
      itemType="Clause"
      itemTypePlural="Control Clauses"
      createItem="{{ createClause }}"
      viewClass="ntb-block-array"
      headerItem={{ this }}
      showAtStart="{{ clauses.length > 0 }}"
      knownTags={{ knownTags }}
      blockType="clause"
      canInheritTags={{ canInheritTags }}
      />
    """
})

export default RactiveClauses

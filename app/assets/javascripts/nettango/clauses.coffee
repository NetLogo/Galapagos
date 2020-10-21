partials = {

  headerTemplate:
    """
    <div class="flex-column">
      <div class="flex-row ntb-form-row">

        <div class="ntb-flex-column">
          <label for="{{ id }}-close">Code format to insert after all clauses</label>
          <codeMirror
            id="{{ id }}-close"
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
            <label for="{{ id }}-{{ number }}-open">Start code format (default is `[`)</label>
            <codeMirror
              id="{{ id }}-{{ number }}-open"
              mode="netlogo"
              code={{ open }}
              extraClasses="['ntb-code-input']"
            />
          </div>

          <div class="ntb-flex-column">
            <label for="{{ id }}-{{ number }}-close">End code format (default is `]`)</label>
            <codeMirror
              id="{{ id }}-{{ number }}-close"
              mode="netlogo"
              code={{ close }}
              extraClasses="['ntb-code-input']"
            />
          </div>

        </div>

        <div class="flex-row ntb-form-row">
          <allowedTags
            id="{{ id }}-{{ number }}-allowed-tags"
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

window.RactiveClauses = Ractive.extend({

  data: () -> {
    blockId:        undefined # Int
    clauses:        []        # Array[NetTangoAttribute]
    closeClauses:   ""        # String
    knownTags:      []        # Array[String]
    canInheritTags: false     # Boolean

    createClause:
      (number) -> {
        open:        undefined
      , close:       undefined
      , children:    []
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
      id="block-{{ blockId }}-clauses"
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

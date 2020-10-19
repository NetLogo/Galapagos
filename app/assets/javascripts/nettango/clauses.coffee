window.RactiveClauses = Ractive.extend({

  data: () -> {
    blockId:      undefined # Int
    clauses:      []        # Array[NetTangoAttribute]
    closeClauses: "" # String

    clauseTemplate:
      """
      <fieldset class="ntb-attribute">
        <legend class="widget-edit-legend">
          {{ itemType }} {{ number }} {{> delete-button }}
        </legend>
        <div class="flex-column">
          <div class="flex-row ntb-form-row">

            <labeledInput name="action" type="text" value="{{ action }}" labelStr="Display name"
              divClass="ntb-flex-column" class="ntb-input" />

            <div class="ntb-flex-column">
              <label for="block-{{ blockId }}-clause-{{ number }}-open">Start code format (default is `[`)</label>
              <codeMirror
                id="block-{{ blockId }}-clause-{{ number }}-open"
                mode="netlogo"
                code={{ open }}
                extraClasses="['ntb-code-input']"
              />
            </div>

            <div class="ntb-flex-column">
              <label for="block-{{ blockId }}-clause-{{ number }}-close">End code format (default is `]`)</label>
              <codeMirror
                id="block-{{ blockId }}-clause-{{ number }}-close"
                mode="netlogo"
                code={{ close }}
                extraClasses="['ntb-code-input']"
              />
            </div>

          </div>
        </div>
      </fieldset>
      """

    clauseHeaderTemplate:
      """
      <div class="flex-column">
        <div class="flex-row ntb-form-row">

          <div class="ntb-flex-column">
            <label for="block-{{ blockId }}-close-clauses">Code format to insert after all clauses</label>
            <codeMirror
              id="block-{{ blockId }}-close-clauses"
              mode="netlogo"
              code={{ closeClauses }}
              extraClasses="['ntb-code-input']"
            />
          </div>

        </div>
      </div>
      """

    createClause:
      (number) -> { open: undefined, close: undefined, children: [] }

  }

  components: {
    arrayView: RactiveArrayView
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <arrayView
      id="block-{{ blockId }}-clauses"
      itemTemplate="{{ clauseTemplate }}"
      items="{{ clauses }}"
      itemType="Clause"
      itemTypePlural="Control Clauses"
      createItem="{{ createClause }}"
      viewClass="ntb-block-array"
      headerItem={{ this }}
      headerTemplate="{{ clauseHeaderTemplate }}"
      showItems="{{ clauses.length > 0 }}"
      />
    """
    # coffeelint: enable=max_line_length
})

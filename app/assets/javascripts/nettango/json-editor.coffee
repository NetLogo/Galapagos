window.RactiveJsonEditor = Ractive.extend({
  data: () -> {
    id:      ""    # String
    json:    ""    # String
    show:    false # Boolean
    isDirty: false # Boolean
  }

  components: {
    codeMirror: RactiveCodeMirror
  }

  template:
    """
    <div class="ntb-block-defs-controls">

      <label class="ntb-toggle-block" >
        <input id="info-toggle" type="checkbox" checked="{{ show }}" />
        <div>{{# show }}▲{{else}}▼{{/}} Block Space Definition</div>
      </label>

      {{# show }}
      <button class="ntb-button" type="button"
        on-click="[ 'ntb-apply-json-to-space', json ]"
        {{# !isDirty }} disabled{{/}}>
        Apply Definition to Space
      </button>
      {{/ show }}

    </div>

    {{# show }}
    <codeMirror
      id={{ id }}
      mode="json"
      code={{ json }}
      config="{ lineNumbers: true, fixedGutter: true }"
      extraClasses="[ 'ntb-json' ]"
      isDirty={{ isDirty }}
    />
    {{/ show }}
    """

})

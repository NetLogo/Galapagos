window.RactiveAttribute = Ractive.extend({

  data: () -> {
    id:            undefined # Integer
    codeFormat:    undefined # String
    attribute:     undefined # NetTangoAttribute
    attributeType: undefined # String ("params" or "properties")
  }

  computed: {
    codeFormatFull: () ->
      "{#{@get('codeFormat') ? ''}#{@get('id')}}"

    elementId: () ->
      "#{@get("attributeType").toLowerCase()}-#{@get("id")}"
  }

  on: {
    # (Context) => Unit
    '*.ntb-attribute-type-changed': (_) ->
      # Reset our default to the appropriate value  - JMB August 2018
      attribute = @get('attribute')
      newDefVal = switch attribute.type
        when 'bool'            then false
        when 'num',   'int'    then 10
        when 'text'            then ""
        when 'range', 'select' then null
        else null
      @set('attribute.def', newDefVal)
      return

    '*.ntb-copy-attribute-format': (_) ->
      # This only works in Firefox and Chrome (maybe Edge?) but not Safari.
      # Better than nothing?  -Jeremy B September 2019
      navigator.clipboard.writeText(@get('codeFormatFull'))
      return
  }

  components: {
    labeledInput: RactiveTwoWayLabeledInput
    dropdown:     RactiveTwoWayDropdown
    select:       RactiveSelectAttribute
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="flex-row ntb-form-row">

      <labeledInput id="{{ elementId }}-name" name="name" type="text" value="{{ attribute.name }}" labelStr="Display name" divClass="ntb-flex-column" class="ntb-input" />

      <dropdown id="{{ elementId }}-type" name="{{ attribute.type }}" selected="{{ attribute.type }}" label="Type" divClass="ntb-flex-column"
        choices="{{ [ 'bool', 'num', 'int', 'range', 'text', 'select' ] }}" changeEvent="ntb-attribute-type-changed"
        />

      <labeledInput id="{{ elementId }}-unit" name="unit" type="text" value="{{ attribute.unit }}" labelStr="Unit label"  divClass="ntb-flex-column" class="ntb-input" />

      <labeledInput id="{{ elementId }}-def"  name="def"  type="text" value="{{ attribute.def }}"  labelStr="Default"     divClass="ntb-flex-column" class="ntb-input" />

      <labeledInput id="{{ elementId }}-code" name="def"  type="text" value="{{ codeFormatFull }}" labelStr="Code format" divClass="ntb-flex-column" class="ntb-input ntb-code-input" twoway="false" attrs="readonly" />

      <div class="ntb-attribute-copy-format" on-click="ntb-copy-attribute-format"></div>

    </div>

    {{> `param-${attribute.type}` }}
    """
    # coffeelint: enable=max_line_length

  partials: {
    # coffeelint: disable=max_line_length
    'param-bool': ""
    'param-num': ""
    'param-int': ""
    'param-text': ""

    'param-select': """<select attribute="{{ attribute }}" elementId="{{ elementId }}" />"""

    'param-range':
      """
      <div class="flex-row">
        <labeledInput id="{{ elementId }}-min"  name="min"  type="number" value="{{ attribute.min }}"  labelStr="Min" divClass="ntb-flex-column" class="ntb-input" />
        <labeledInput id="{{ elementId }}-max"  name="max"  type="number" value="{{ attribute.max }}"  labelStr="Max" divClass="ntb-flex-column" class="ntb-input" />
        <labeledInput id="{{ elementId }}-step" name="step" type="number" value="{{ attribute.step }}" labelStr="Step size" divClass="ntb-flex-column" class="ntb-input" />
        <div class="ntb-flex-column" />
      </div>
      """
    # coffeelint: enable=max_line_length
  }
})

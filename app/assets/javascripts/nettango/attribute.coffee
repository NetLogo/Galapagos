import { RactiveTwoWayLabeledInput } from "/beak/widgets/ractives/subcomponent/labeled-input.js"
import { RactiveTwoWayDropdown } from "/beak/widgets/ractives/subcomponent/dropdown.js"
import RactiveSelectAttribute from "./select-attribute.js"

RactiveAttribute = Ractive.extend({

  data: () -> {
    id:            undefined # Integer
    codeFormat:    undefined # String
    attribute:     undefined # NetTangoAttribute
    attributeType: undefined # String ('params' | 'properties')
    valueType:     undefined # String ('bool' | 'num' | 'int' | 'range' | 'text' | 'select')
    quoteOptions:  undefined # Array[String]
  }

  computed: {

    codeFormatFull: () ->
      "{#{@get('codeFormat') ? ''}#{@get('id')}}"

    defaultType: () ->
      type = @get("attribute.type")
      switch type
        when 'int', 'range' then 'number'
        else                     'text'

    elementId: () ->
      "#{@get("attributeType").toLowerCase()}-#{@get("id")}"

  }

  on: {

    # (Context) => Unit
    'init': (_) ->
      valueType = @get('attribute.type')
      @set('valueType', valueType)
      quoteOptions = Object.keys(NetTango.selectQuoteOptions).map( (key) -> NetTango.selectQuoteOptions[key] )
      @set("quoteOptions", quoteOptions)
      return

    # (Context) => Unit
    '*.ntb-attribute-type-changed': (_) ->
      # Reset our default to the appropriate value  - JMB August 2018
      attribute      = @get('attribute')
      attribute.type = @get('valueType')
      attribute.def  = switch attribute.type
        when 'int', 'range'    then 10
        when 'text', 'select'  then ''
        when 'num'             then '0'
        when 'bool'            then 'false'
        else null
      @set('attribute', attribute)
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

      <dropdown id="{{ elementId }}-type" name="{{ valueType }}" selected="{{ valueType }}" label="Type" divClass="ntb-flex-column"
        choices="{{ [ 'bool', 'num', 'int', 'range', 'text', 'select' ] }}" changeEvent="ntb-attribute-type-changed"
        />

      <labeledInput id="{{ elementId }}-unit" name="unit" type="text" value="{{ attribute.unit }}" labelStr="Unit label" divClass="ntb-flex-column" class="ntb-input" />

      {{# defaultType === 'number' }}
        <labeledInput id="{{ elementId }}-def" name="def" type="number" value="{{ attribute.def }}" labelStr="Default" divClass="ntb-flex-column" class="ntb-input" />
      {{else}}
        <labeledInput id="{{ elementId }}-def" name="def" type="text" value="{{ attribute.def }}" labelStr="Default" divClass="ntb-flex-column" class="ntb-input" />
      {{/if}}

      <labeledInput id="{{ elementId }}-code" type="text" value="{{ codeFormatFull }}" labelStr="Code format" divClass="ntb-flex-column" class="ntb-input ntb-code-input" twoway="false" attrs="readonly" />

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

    'param-text':
      """
      <div class="flex-row ntb-form-row">
        <dropdown
          id="{{ elementId }}-quoted"
          name="{{ attribute.quoteValues }}"
          selected="{{ attribute.quoteValues }}"
          label="Quote values in code"
          divClass="ntb-flex-column"
          choices="{{ quoteOptions }}"
        />

        <div class="ntb-flex-column" />
      </div>
      """

    'param-select':
      """
      <select
        attribute="{{ attribute }}"
        elementId="{{ elementId }}"
        quoteOptions="{{ quoteOptions }}"
      />
      """

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

export default RactiveAttribute

RactiveToggle = Ractive.extend({

  data: () -> {
    show:         false # Boolean
    showAtStart:  false # Boolean
    enableToggle: true  # Boolean
  }

  oninit: () ->
    showAtStart = @get('showAtStart')
    @set('show', showAtStart)
    return

  template:
    # coffeelint: disable=max_line_length
    """
    <fieldset class="widget-edit-fieldset ntb-block-array {{# !show }}ntb-array-view-hidden{{/ show }}">
      <legend class="widget-edit-legend">

        {{> titleTemplate }}

        {{# enableToggle }}
        <label class="ntb-toggle-block">
          <input type="checkbox" checked="{{ show }}" />
          {{# show }}▲{{else}}▼{{/}}
        </label>
        {{/ enableToggle }}

      </legend>

      {{# show }}

      {{> contentTemplate }}

      {{/ show }}

    </fieldset>
    """
    # coffeelint: enable=max_line_length
})

export default RactiveToggle

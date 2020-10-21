window.RactiveToggle = Ractive.extend({

  data: () -> {
    show:        false # Boolean
    showAtStart: false # () => Boolean
  }

  oninit: () ->
    showAtStart = @get('showAtStart')
    @set('show', showAtStart)
    return

  template:
    # coffeelint: disable=max_line_length
    """
    <fieldset class="widget-edit-fieldset flex-column ntb-block-array {{# !show }}ntb-array-view-hidden{{/ show }}">
      <legend class="widget-edit-legend">

        {{> titleTemplate }}

        <label class="ntb-toggle-block">
          <input type="checkbox" checked="{{ show }}" />
          {{# show }}▲{{else}}▼{{/}}
        </label>

      </legend>

      {{# show }}

      {{> contentTemplate }}

      {{/ show }}

    </fieldset>
    """
    # coffeelint: enable=max_line_length
})

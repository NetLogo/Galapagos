window.RactiveNetTangoOptionsForm = EditForm.extend({

  data: () -> {
    submitLabel: "Apply Options"   # String
    cancelLabel: "Discard Changes" # String
    tabOptions:  {}   # Map[String, TabOption]
    toggles:     {}   # Map[String, NetTangoToggle]
    extraCss:    null # String
  }

  on: {

    # (Context) => Unit
    'submit': (_) ->
      @fire("ntb-options-updated", {}, @get("tabOptions"), @get("toggles"), @get("extraCss"))
      return

  }

  oninit: ->
    @_super()

  show: (tabOptions, toggles, extraCss) ->
    @set("tabOptions", tabOptions)
    @set("toggles", toggles)
    @set("extraCss", extraCss)
    @fire("show-yourself")
    return

  genProps: (_) ->
    null

  twoway: true

  partials: {

    title: "NetTango Model Options"

    widgetFields:
      # coffeelint: disable=max_line_length
      """
      <div class="netlogo-display-horizontal">

        <ul style-list-style="none">
        {{#tabOptions:key }}<li>
          <input id="ntb-{{ key }}" type="checkbox" name="{{ key }}" checked="{{ checked }}">
          <label for="ntb-{{ key }}">{{ label }}</label>
        </li>{{/tabOptions }}
        </ul>

        <ul style-list-style="none">

        {{#toggles:key }}<li>
          <input id="ntb-{{ key }}" type="checkbox" name="{{ key }}" checked="{{ checked }}">
          <label for="ntb-{{ key }}">{{ label }}</label>
        </li>{{/toggles }}
        </ul>

      </div>

      <div class="ntb-block-defs-controls">
        <label for="ntb-extra-css">Extra CSS to include</label>
      </div>

      <textarea id="ntb-extra-css" type="text" value="{{ extraCss }}" ></textarea>
      """
      # coffeelint: enable=max_line_length
  }
})

window.RactiveOptionsForm = EditForm.extend({

  data: () -> {
    submitLabel:   "Apply Options"   # String
    cancelLabel:   "Discard Changes" # String
    confirmDialog: undefined         # RactiveConfirmDialog
    options:       undefined         # Object
  }

  on: {

    # (Context) => Unit
    'submit': (_) ->
      @fire("ntb-options-updated", {}, @get("options"))
      return

    'ntb-confirm-clear-all-block-styles': (_) ->
      @get('confirmDialog').show({
        text:    "Do you want to clear existing styles from all blocks in all workspaces?  This cannot be undone.",
        approve: { text: "Yes, clear all block styles", event: "ntb-clear-all-block-styles" },
        deny:    { text: "No, leave block styles in place" }
      }, "250px")
      return false

  }

  oninit: ->
    @_super()

  show: (options) ->
    clonedOptions = {}
    [ "tabOptions", "netTangoToggles", "extraCss", "blockStyles" ]
      .forEach( (prop) ->
        if options.hasOwnProperty(prop)
          clonedOptions[prop] = JSON.parse(JSON.stringify(options[prop]))
      )
    @set("options", clonedOptions)

    @fire("show-yourself")
    return

  genProps: (_) ->
    null

  twoway: true

  components: {
    blockStyle: RactiveBlockStyleSettings
    codeMirror: RactiveCodeMirror
  }

  partials: {

    title: "NetTango Model Options"

    widgetFields:
      # coffeelint: disable=max_line_length
      """
      {{# options }}

      <div class="netlogo-display-horizontal">

        <ul style-list-style="none">
        {{# tabOptions:key }}<li>
          <input id="ntb-{{ key }}" type="checkbox" name="{{ key }}" checked="{{ checked }}">
          <label for="ntb-{{ key }}">{{ label }}</label>
        </li>{{/ tabOptions }}
        </ul>

        <ul style-list-style="none">

        {{# netTangoToggles:key }}<li>
          <input id="ntb-{{ key }}" type="checkbox" name="{{ key }}" checked="{{ checked }}">
          <label for="ntb-{{ key }}">{{ label }}</label>
        </li>{{/ netTangoToggles }}
        </ul>

      </div>

      <div class="ntb-block-defs-controls">
        <button class="ntb-button" type="button" on-click="ntb-confirm-clear-all-block-styles">Remove existing styles from all blocks</button>
      </div>

      <blockStyle
        title="Procedure Block Styles"
        styleId="procedure-blocks"
        styleSettings="{{ blockStyles.starterBlockStyle }}"
        showClear="false"
        showAtStart="true"
        >
      </blockStyle>

      <blockStyle
        title="Control Block Styles"
        styleId="control-blocks"
        styleSettings="{{ blockStyles.containerBlockStyle }}"
        showClear="false"
        showAtStart="true"
        >
      </blockStyle>

      <blockStyle
        title="Command Block Styles"
        styleId="command-blocks"
        styleSettings="{{ blockStyles.commandBlockStyle }}"
        showClear="false"
        showAtStart="true"
        >
      </blockStyle>

      <div class="ntb-block-defs-controls">
        <label for="ntb-extra-css">Extra CSS to include</label>
      </div>

      <codeMirror
        id="ntb-extra-css"
        mode="css"
        code="{{ extraCss }}"
        extraClasses="['ntb-code']"
      />

      {{/ options }}
      """
      # coffeelint: enable=max_line_length
  }
})

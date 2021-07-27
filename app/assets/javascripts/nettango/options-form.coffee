import RactiveBlockStyleSettings from "./block-style-settings.js"
import RactiveCodeMirror from "./code-mirror.js"
import RactiveModalDialog from "./modal-dialog.js"
import ObjectUtils from "./object-utils.js"
import { netLogoOptionInfo, netTangoOptionInfo } from "./options.js"

RactiveOptionsForm = RactiveModalDialog.extend({

  clearAllTarget: null

  data: () -> {
    deny:               { text: "Discard Changes" }
    options:            undefined
    top:                150
    netLogoOptionInfo:  netLogoOptionInfo
    netTangoOptionInfo: netTangoOptionInfo
  }

  on: {
    'ntb-confirm-clear-all-block-styles': (context) ->
      @fire('show-confirm-dialog', context, {
        text: "Do you want to clear existing styles from all blocks in all workspaces?  This cannot be undone."
      , approve: {
          text: "Yes, clear all block styles"
        , event: "ntb-clear-all-block-styles"
        , target: @target
        }
      , deny: { text: "No, leave block styles in place" }
      })
      return
  }

  show: (target, options) ->
    @target = target
    clonedOptions = {}
    [ "tabOptions", "netTangoToggles", "extraCss", "blockStyles" ]
      .forEach( (prop) ->
        if options.hasOwnProperty(prop) and options[prop]?
          clonedOptions[prop] = ObjectUtils.clone(options[prop])
      )
    @set('options', clonedOptions)
    @set('approve', {
      text: "Apply Options"
    , event: "ntb-options-updated"
    , argsMaker: (() => [@get('options')])
    , target: target
    })
    @_super()
    return

  components: {
    blockStyle: RactiveBlockStyleSettings
    codeMirror: RactiveCodeMirror
  }

  partials: {

    headerContent: "NetTango Model Options"
    dialogContent:
      # coffeelint: disable=max_line_length
      """
      {{# options }}

      <div class="netlogo-display-horizontal">

        <ul style-list-style="none">
        {{# tabOptions:key }}<li>
          <input id="ntb-{{ key }}" type="checkbox" name="{{ key }}" checked="{{ tabOptions[key] }}">
          <label for="ntb-{{ key }}">{{ netLogoOptionInfo[key].label }}</label>
        </li>{{/ tabOptions }}
        </ul>

        <ul style-list-style="none">

        {{# netTangoToggles:key }}<li>
          <input id="ntb-{{ key }}" type="checkbox" name="{{ key }}" checked="{{ netTangoToggles[key] }}">
          <label for="ntb-{{ key }}">{{ netTangoOptionInfo[key].label }}</label>
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

export default RactiveOptionsForm

window.RactiveNetTangoBuilder = Ractive.extend({
  on: {

    'ntb-refresh-css': (_) ->
      @refreshCss()

    'ntb-clear-all-check': ({ event: { pageX, pageY } }) ->
      clearMenu = {
        name: "_",
        items: [
          {
            name: 'Are you sure?',
            items: [
              { name: 'Yes, clear all data', eventName: 'ntb-clear-all' }
            ]
          }
        ]
      }
      @popupmenu.popup(@, pageX, pageY, clearMenu)
      return false

    '*.ntb-clear-all': (_) ->
      # TODO - vomit
      modelContainer = document.getElementById('model-container')
      blankData = {
          code:       modelContainer.contentWindow.exports.newModel
        , spaces:     []
        , extraCss:   ""
        , title:      "Blank Model"
        , tabOptions: {
            commandCenterTab: true
          , codeTab:          true
          , infoTab:          true
          , speedBar:         true
          , fileButtons:      true
          , authoring:        true
          , poweredBy:        false
        }
      }
      @load(blankData)

    'ntb-create-blockspace': (_) ->
      defsComponent = @findComponent('tangoDefs')
      defsComponent.createSpace({ defs: { blocks: [] } })
      return

  }

  components: {
    tangoDefs:     RactiveNetTangoDefs
  }

  data: () -> {
    # These are the NetTango Builder controlling variables
    playMode:        false,
    lastCss:         "",
    extraCssIsDirty: false,
    blockEditor: {
      show:        false,
      spaceNumber: undefined,
      blockNumber: undefined,
      submitEvent: undefined,
      submitLabel: "Add New Block"
    },
    # Dependency injection :-P  -JMB
    findElement:   () ->,
    createElement: () ->,
    appendElement: () ->,
    # Below are the actual NetTango Builder data points
    extraCss: "",
    title: "Blank Model",
    tabOptions: {
      commandCenterTab: {
        label: "Hide command center tab",
        checked: true,
        checkedCssBuild:  'div.netlogo-tab-area > label:nth-of-type(1) { background: #eee; }',
        checkedCssExport: 'div.netlogo-tab-area > label:nth-of-type(1) { display: none; }'
      },
      codeTab: {
        label: "Hide code tab",
        checked: true,
        checkedCssBuild:  'div.netlogo-tab-area > label:nth-of-type(2) { background: #eee; }',
        checkedCssExport: 'div.netlogo-tab-area > label:nth-of-type(2) { display: none; }'
      },
      infoTab: {
        label: "Hide info tab",
        checked: true,
        checkedCssBuild:  'div.netlogo-tab-area > label:nth-of-type(3) { background: #eee; }',
        checkedCssExport: 'div.netlogo-tab-area > label:nth-of-type(3) { display: none; }'
      },
      speedBar: {
        label: "Hide model speed bar",
        checked: true,
        checkedCssBuild:  '.netlogo-speed-slider { display: none; }',
        checkedCssExport: '.netlogo-speed-slider { display: none; }'
      },
      fileButtons: {
        label: "Hide file and export buttons",
        checked: true,
        checkedCssBuild:  '.netlogo-export-wrapper { display: none; }',
        checkedCssExport: '.netlogo-export-wrapper { display: none; }'
      },
      authoring: {
        label: "Hide authoring unlock",
        checked: true,
        checkedCssBuild:  '.netlogo-interface-unlocker-container { background: #eee; }',
        checkedCssExport: '.netlogo-interface-unlocker-container { display: none; }'
      }
      poweredBy: {
        label: "Hide 'Powered by NetLogo' link",
        checked: false,
        checkedCssBuild:  '.netlogo-powered-by { display: none; }',
        checkedCssExport: '.netlogo-powered-by { display: none; }'
      }
    }
  }

  checkForDirtyCss: () ->
    lastCss  = @get('lastCss')
    extraCss = @get('extraCss')
    @set('extraCssIsDirty', lastCss isnt extraCss)

  getNetTangoBuilderData: () ->
    spaces = @findComponent('tangoDefs').get('spaces')
    tabOptions = { }
    tabOptionValues = @get('tabOptions')
    Object.getOwnPropertyNames(tabOptionValues)
      .forEach((n) -> tabOptions[n] = tabOptionValues[n].checked)

    {
        spaces,
      , tabOptions
      , title:    @get('title')
      , extraCss: @get('extraCss')
    }

  getEmptyNetTangoProcedures: () ->
    spaces = @findComponent('tangoDefs').get('spaces')
    spaceProcs = for _, space of spaces
      space.defs.blocks.filter((b) => b.type is 'nlogo:procedure').map((b) => b.format + "\nend").join("\n")
    spaceProcs.join("\n")

  refreshCss: () ->
    # we use a fancy "CSS Injection" technique to get styles applied to the model iFrame.
    styleElement = @get('findElement')('ntb-injected-style')

    if (not styleElement)
      styleElement    = @get('createElement')('style')
      styleElement.id = 'ntb-injected-style'
      @get('appendElement')(styleElement)

    extraCss = @get('extraCss')
    @set('lastCss', extraCss)
    @set('extraCssIsDirty', false)

    styleElement.innerHTML = @compileCss(@get('playMode'), extraCss)
    return

  compileCss: (forExport, extraCss) ->
    newCss     = ''
    tabOptions = @get('tabOptions')
    for name, option of tabOptions
      if(option.checked and option.checkedCssBuild isnt '')
        newCss = "#{newCss}\n#{if (forExport) then option.checkedCssExport else option.checkedCssBuild}"

    newCss   = "#{newCss}\n#{extraCss}"
    # override the rounded corners of tabs to make them easier to hide with CSS and without JS
    # TODO - find a better way to store these values
    # coffeelint: disable=max_line_length
    newCss = newCss + '\n.netlogo-tab:first-child { border-radius: 0px; }'
    newCss = newCss + '\n.netlogo-tab:last-child, .netlogo-tab-content:last-child { border-radius: 0px; border-bottom-width: 1px; }'
    newCss = newCss + '\n.netlogo-tab { border: 1px solid rgb(36, 36, 121); }'
    newCss = newCss + '\n.netlogo-tab-area { margin: 0px; }'
    # coffeelint: enable=max_line_length
    newCss

  load: (ntData) ->
    # load spaces and block definitions
    defsComponent = @findComponent('tangoDefs')
    defsComponent.set('spaces', [])
    for spaceVals in (ntData.spaces ? [])
      defsComponent.createSpace(spaceVals)

    # load tab options
    tabOptions = @get('tabOptions')
    for key, prop of (ntData.tabOptions ? { })
      if tabOptions.hasOwnProperty(key)
        @set("tabOptions.#{key}.checked", prop)

    # load other properties
    for propName in [ 'extraCss' ]
      if ntData.hasOwnProperty(propName)
        @set(propName, ntData[propName])

    defsComponent.set('code', '')
    defsComponent.set('lastCode', '')
    defsComponent.set('codeIsDirty', false)

    if(not @get('playMode') and ntData.code?)
      @fire('ntb-netlogo-code-change', ntData.title, ntData.code)

    @refreshCss()
    return

  setPopupMenu: (popupmenu) ->
    @popupmenu = popupmenu
    @set('popupmenu', popupmenu)
    return

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-container" style="position: relative;">

      <div class="ntb-controls">
        {{# !playMode }}
        <div class="ntb-block-defs-controls">
          <button class="ntb-button" on-click="ntb-create-blockspace" >Add New Block Space</button>
          <button class="ntb-button" on-click="ntb-refresh-css"{{# !extraCssIsDirty }} disabled{{/}}>Refresh Model Styles</button>
          <button class="ntb-button" on-click="ntb-save" >Save NetTango Progress</button>
          <button class="ntb-button" on-click="ntb-export-nettango" >Export NetTango Page</button>
          <button id="clear-all-button" class="ntb-button" on-click="ntb-clear-all-check" >Clear Model and Spaces</button>
          <button class="ntb-button" on-click="ntb-export-nettango-json" >Export NetTango JSON</button>
          <label class="ntb-file-label">Import NetTango JSON<input class="ntb-file-button" type="file" on-change="ntb-import-nettango-json" ></label>
        </div>
        {{/}}

        <tangoDefs id="ntb-defs" playMode={{ playMode }} popupmenu={{ popupmenu }} />

        {{# !playMode }}
          <ul style-list-style="none">
          {{#tabOptions:key }}<li>
            <input id="ntb-{{ key }}" type="checkbox" name="{{ key }}" checked="{{ checked }}" on-change="@this.refreshCss()">
            <label for="ntb-{{ key }}">{{ label }}</label>
          </li>{{/tabOptions }}
          </ul>

          <label for="ntb-extra-css">Extra CSS to include</label>
          <textarea id="ntb-extra-css" type="text" on-change-keyup-paste="@this.checkForDirtyCss()" value="{{ extraCss }}" ></textarea>
          <style id="ntb-injected-css" type="text/css">{{ computedCss }}</style>
        {{/}}
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})

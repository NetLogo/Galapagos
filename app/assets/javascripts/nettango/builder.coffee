blockStyleDefaults = {
  starterBlockStyle: {
    blockColor:  "#bb5555"
    textColor:   "#ffffff"
    borderColor: "#ffffff"
    fontWeight:  ""
    fontSize:    ""
    fontFace:    ""
  }

  containerBlockStyle: {
    blockColor:  "#8899aa"
    textColor:   "#ffffff"
    borderColor: "#ffffff"
    fontWeight:  ""
    fontSize:    ""
    fontFace:    ""
  }

  commandBlockStyle: {
    blockColor:  "#9977aa"
    textColor:   "#ffffff"
    borderColor: "#ffffff"
    fontWeight:  ""
    fontSize:    ""
    fontFace:    ""
  }
}

getBlockStyleDefaults = (style) ->
  JSON.parse(JSON.stringify(blockStyleDefaults[style]))

window.RactiveBuilder = Ractive.extend({

  data: () -> {
    canRedo:       false     # Boolean
    canUndo:       false     # Boolean
    confirmDialog: undefined # RactiveConfirmDialog
    allTags:       []        # Array[String]
    knownTags:     []        # Array[String]
    breeds:        []        # Array[String]
    isDebugMode:   false     # Boolean
    newModel:      undefined # String
    playMode:      false     # Boolean
    popupMenu:     undefined # RactivePopupMenu
    runtimeMode:   "dev"     # String

    blockEditor: {
      show:        false           # Boolean
      spaceNumber: undefined       # Integer
      blockIndex:  undefined       # Integer
      submitEvent: undefined       # String
      submitLabel: "Add New Block" # String
    }

    title: "Blank Model" # String

    tabOptions: {
      commandCenterTab: {
        label: "Hide command center tab"
        checked: true
        checkedCssBuild:  'div.netlogo-tab-area > label:nth-of-type(1) { background: #eee; }'
        checkedCssExport: 'div.netlogo-tab-area > label:nth-of-type(1) { display: none; }'
      }
      codeTab: {
        label: "Hide code tab"
        checked: true
        checkedCssBuild:  'div.netlogo-tab-area > label:nth-of-type(2) { background: #eee; }'
        checkedCssExport: 'div.netlogo-tab-area > label:nth-of-type(2) { display: none; }'
      }
      infoTab: {
        label: "Hide info tab"
        checked: true
        checkedCssBuild:  'div.netlogo-tab-area > label:nth-of-type(3) { background: #eee; }'
        checkedCssExport: 'div.netlogo-tab-area > label:nth-of-type(3) { display: none; }'
      }
      speedBar: {
        label: "Hide model speed bar"
        checked: true
        checkedCssBuild:  '.netlogo-speed-slider { background: #eee; }'
        checkedCssExport: '.netlogo-speed-slider { display: none; }'
      }
      fileButtons: {
        label: "Hide file and export buttons"
        checked: true
        checkedCssBuild:  '.netlogo-export-wrapper { background: #eee; }'
        checkedCssExport: '.netlogo-export-wrapper { display: none; }'
      }
      authoring: {
        label: "Hide authoring unlock toggle"
        checked: true
        checkedCssBuild:  '#authoring-lock { background: #eee; }'
        checkedCssExport: '#authoring-lock { display: none; }'
      }
      tabsPosition: {
        label: "Hide commands and code position toggle"
        checked: true
        checkedCssBuild:  '#tabs-position { background: #eee; }'
        checkedCssExport: '#tabs-position { display: none; }'
      }
      poweredBy: {
        label: "Hide 'Powered by NetLogo' link"
        checked: false
        checkedCssBuild:  '.netlogo-powered-by { background: #eee; }'
        checkedCssExport: '.netlogo-powered-by { display: none; }'
      }
    }

    netTangoToggles: {
      workspaceBelow: {
        label: "Show NetTango spaces below the NetLogo model"
        checked: true
      },
      showCode: {
        label: "Show the generated NetLogo Code below the NetTango spaces"
        checked: true
      }
    }

    blockStyles: {
      starterBlockStyle:   getBlockStyleDefaults("starterBlockStyle")
      containerBlockStyle: getBlockStyleDefaults("containerBlockStyle")
      commandBlockStyle:   getBlockStyleDefaults("commandBlockStyle")
    }

    extraCss: "" # String
  }

  on: {

    # (Context) => Unit
    'complete': (_) ->
      confirmDialog = @findComponent('confirmDialog')
      @set('confirmDialog', confirmDialog)
      return

    # () => Boolean
    '*.ntb-clear-all-check': () ->
      @get('confirmDialog').show({
        text:    "Do you want to clear your model and workspaces?",
        approve: { text: "Yes, clear all data", event: "ntb-clear-all" },
        deny:    { text: "No, leave workspaces unchanged" }
      })
      return false

    # (Context) => Unit
    '*.ntb-clear-all': (_) ->
      blankData = {
        code:       @get('newModel')
        spaces:     []
        title:      "Blank Model"
        tabOptions: {
          commandCenterTab: true
          codeTab:          true
          infoTab:          true
          speedBar:         true
          fileButtons:      true
          authoring:        true
          poweredBy:        false
        }
        netTangoToggles: {
          workspaceBelow: true
          showCode:       true
        }
        blockStyles: {
          starterBlockStyle:   getBlockStyleDefaults("starterBlockStyle")
          containerBlockStyle: getBlockStyleDefaults("containerBlockStyle")
          commandBlockStyle:   getBlockStyleDefaults("commandBlockStyle")
        }
        extraCss: ""
      }
      @fire("ntb-load-project", {}, blankData)
      return

    '*.ntb-clear-all-block-styles': (_) ->
      spacesComponent = @findComponent('tangoDefs')
      spacesComponent.clearBlockStyles()
      return

    # (Context) => Unit
    '*.ntb-create-blockspace': (_) ->
      defsComponent = @findComponent('tangoDefs')
      defsComponent.createSpace({ defs: { blocks: [] } })
      return

    '*.ntb-import-netlogo-prompt': (_) ->
      importInput = @find('#ntb-import-netlogo')
      importInput.value = ""
      importInput.click()
      return false

    '*.ntb-choose-netlogo-prompt': (_) ->
      @findComponent('modelChooser').show()
      return false

    '*.ntb-import-json-prompt': (_) ->
      importInput = @find('#ntb-import-json')
      importInput.value = ""
      importInput.click()
      return false

    '*.ntb-show-options': (_) ->
      tabOptions      = @get("tabOptions")
      netTangoToggles = @get("netTangoToggles")
      blockStyles     = @get("blockStyles")
      extraCss        = @get("extraCss")

      optionsForm = @findComponent("optionsForm")
      optionsForm.show({
        tabOptions,
        netTangoToggles,
        blockStyles,
        extraCss
      })
      overlay = @root.find(".widget-edit-form-overlay")
      overlay.classList.add("ntb-dialog-overlay")
      return

    '*.ntb-options-updated': (_, options) ->
      tabOptions = @get("tabOptions")
      Object.getOwnPropertyNames(options.tabOptions)
        .forEach( (n) ->
          if tabOptions.hasOwnProperty(n)
            tabOptions[n].checked = options.tabOptions[n].checked
        )

      netTangoToggles = @get("netTangoToggles")
      Object.getOwnPropertyNames(options.netTangoToggles)
        .forEach( (n) =>
          if netTangoToggles.hasOwnProperty(n)
            @set("netTangoToggles.#{n}.checked", options.netTangoToggles[n].checked)
        )

      oldStyles = JSON.parse(JSON.stringify(@get("blockStyles")))
      [ "starterBlockStyle", "containerBlockStyle", "commandBlockStyle" ]
        .forEach( (prop) =>
          if options.blockStyles.hasOwnProperty(prop)
            @set("blockStyles.#{prop}", options.blockStyles[prop])
        )
      newStyles = @get("blockStyles")
      blockStylesChanged = [ "starterBlockStyle", "containerBlockStyle", "commandBlockStyle" ]
        .some( (prop) ->
          [ "blockColor", "textColor", "borderColor", "fontWeight", "fontSize", "fontFace" ]
           .some( (styleProp) ->
             oldStyles[prop]?[styleProp] isnt newStyles[prop]?[styleProp]
           )
        )

      if blockStylesChanged
        spacesComponent = @findComponent('tangoDefs')
        spacesComponent.updateNetTango()

      @set("extraCss", options.extraCss)

      @refreshCss()
      @moveSpaces(netTangoToggles.workspaceBelow.checked, @get('playMode'))
      @fire("ntb-options-changed")
      return

  }

  observe: {

    'breeds': () ->
      @initializeTags(@get('knownTags'), @findComponent('tangoDefs').get('spaces'))

  }

  # () => NetTangoBuilderData
  getNetTangoBuilderData: () ->
    spaces = @findComponent('tangoDefs').get('spaces')

    netTangoToggles = { }
    netTangoToggleValues = @get('netTangoToggles')
    Object.getOwnPropertyNames(netTangoToggleValues)
      .forEach((n) -> netTangoToggles[n] = netTangoToggleValues[n].checked)

    tabOptions = { }
    tabOptionValues = @get('tabOptions')
    Object.getOwnPropertyNames(tabOptionValues)
      .forEach((n) -> tabOptions[n] = tabOptionValues[n].checked)

    {
        spaces,
      , netTangoToggles
      , tabOptions
      , blockStyles: @get('blockStyles')
      , title:       @get('title')
      , extraCss:    @get('extraCss')
    }

  # () => String
  getEmptyNetTangoProcedures: () ->
    spaces = @findComponent('tangoDefs').get('spaces')
    spaceProcs = for _, space of spaces
      space.defs.blocks.filter((b) => b.type is 'nlogo:procedure').map((b) => b.format + "\nend").join("\n")
    spaceProcs.join("\n")

  # (Boolean) => Unit
  moveSpaces: (workspaceBelow, playMode) ->
    # The main wrapper for the builder lives outside Ractive,
    # so we imperatively update the CSS classes instead of
    # using a template.  -Jeremy B July 2019
    content = document.getElementById('ntb-container')
    options = document.getElementById('ntb-components')
    if (workspaceBelow)
      content.classList.remove('netlogo-display-horizontal')
      options.style.minWidth = ""
    else
      content.classList.add('netlogo-display-horizontal')
      if (playMode)
        options.style.minWidth = "auto"

  # () => Unit
  refreshCss: () ->
    styleElement           = @find('#ntb-injected-style')
    styleElement.innerHTML = @compileCss(@get('playMode'), @get('extraCss'))
    return

  # (Boolean, String) => String
  compileCss: (forExport, extraCss) ->
    tabOptions = @get('tabOptions')

    newCss = Object.getOwnPropertyNames(tabOptions)
      .filter( (prop) -> tabOptions[prop].checked and tabOptions[prop].checkedCssBuild isnt '' )
      .map( (prop) -> if (forExport) then tabOptions[prop].checkedCssExport else tabOptions[prop].checkedCssBuild )

    # This is hack to get the bottom borders in the tab area correct, since I cannot conjure
    # any CSS-only solution to handle it.  At some point it might be better to move this
    # to a pure JS solution to hide tabs directly in code, but that would require model
    # updates.  -Jeremy B July 2020
    tabAreaCss = if not forExport then [] else
      tabAreaBorder = if (tabOptions.commandCenterTab?.checked and
        tabOptions.codeTab?.checked and tabOptions.infoTab?.checked
      )
        'div.netlogo-tab-area { border: 0px; }'
      else
        ''

      commandBorder = if (not tabOptions.commandCenterTab?.checked and (
        not tabOptions.codeTab?.checked or not tabOptions.infoTab?.checked
      ))
        'div.netlogo-tab-area > label:nth-of-type(1) { border-bottom: 1px solid; }'
      else
        'div.netlogo-tab-area > label:nth-of-type(1) { border-bottom: 0px; }'

      codeBorder = if (not tabOptions.codeTab?.checked and not tabOptions.infoTab?.checked)
        'div.netlogo-tab-area > label:nth-of-type(2) { border-bottom: 1px solid; }'
      else
        'div.netlogo-tab-area > label:nth-of-type(2) { border-bottom: 0px; }'

      [tabAreaBorder, commandBorder, codeBorder]

    newCss = newCss.concat([extraCss, '.netlogo-tab-area { margin: 0px; }'], tabAreaCss)

    newCss.join('\n')

  # (Array[String], Array[String]) -> Unit
  pushUnique: (values, newValues) ->
    newValues.forEach( (v) ->
      if not values.includes(v)
        values.push(v)
      return
    )
    return

  # (Array[NetTangoClause]) -> Array[String]
  getTagsFromClauses: (clauses) ->
    clauses.flatMap( (c) ->
      if (c.allowedTags? and c.allowedTags.type is 'any-of') then c.allowedTags.tags else []
    )

  # (Array[NetTangoBlock]) -> Array[String]
  getTagsFromBlocks: (blocks) ->
    blocks.flatMap( (b) =>
      blockTags   = b.tags ? []
      allowedTags = if (b.allowedTags? and b.allowedTags.type is 'any-of') then b.allowedTags.tags else []
      clauseTags  = @getTagsFromClauses(b.clauses ? [])
      blockTags.concat(allowedTags).concat(clauseTags)
    )

  # (Array[String], Array[NetTangoSpace]) -> Unit
  initializeTags: (knownTags, spaces) ->
    # It's possible there are tags on the blocks that somehow weren't included (manual JSON edits?), so always
    # do a check through them.  -Jeremy B October 2020
    blockTags = spaces.flatMap( (s) => @getTagsFromBlocks(s.defs.blocks) )
    @pushUnique(knownTags, blockTags)
    @set('knownTags', knownTags)

    allTags   = knownTags.slice(0)
    breedTags = @get('breeds')
    @pushUnique(allTags, breedTags)
    @set('allTags', allTags)

    return

  # (NetTangoProject) => Unit
  load: (project) ->
    # Make sure styles are loaded first, as when spaces are added
    # they initialize NetTango workspaces with them.  -Jeremy B Jan-2020
    blockStyles = @get("blockStyles")
    for propName in [ "starterBlockStyle", "containerBlockStyle", "commandBlockStyle" ]
      if (project.hasOwnProperty("blockStyles") and project.blockStyles.hasOwnProperty(propName))
        blockStyles[propName] = project.blockStyles[propName]
      else
        blockStyles[propName] = getBlockStyleDefaults(propName)

    defsComponent = @findComponent('tangoDefs')
    defsComponent.set('spaces', [])
    for spaceVals in (project.spaces ? [])
      defsComponent.createSpace(spaceVals)
    defsComponent.updateCode()

    @initializeTags(project["knownTags"] ? [], defsComponent.get('spaces'))

    tabOptions = @get('tabOptions')
    for key, prop of (project.tabOptions ? { })
      if tabOptions.hasOwnProperty(key)
        tabOptions[key].checked = prop

    netTangoToggles = @get('netTangoToggles')
    for key, prop of (project.netTangoToggles ? { })
      if netTangoToggles.hasOwnProperty(key)
        netTangoToggles[key].checked = prop
    @set("netTangoToggles", netTangoToggles)

    @set("extraCss", if project.hasOwnProperty("extraCss") then project.extraCss else "")

    if (project.code?)
      @fire('ntb-model-change', project.title, project.code)
    else
      @fire('ntb-model-change', "New Model", @get('newModel'))

    @refreshCss()
    @moveSpaces(netTangoToggles.workspaceBelow.checked, @get('playMode'))

    # If this was an import, clear the value so we can re-import the same file in Chrome and Safari - JMB August 2018
    importInput = @find('#ntb-import-json')
    if importInput?
      importInput.value = ''

    return

  components: {
      builderMenu:   RactiveBuilderMenu
    , confirmDialog: RactiveConfirmDialog
    , modelChooser:  RactiveModelChooser
    , optionsForm:   RactiveOptionsForm
    , tangoDefs:     RactiveSpaces
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <style id="ntb-injected-style"></style>
    <div class="ntb-builder">
      <optionsForm parentClass="ntb-builder" idBasis="ntb-options" verticalOffset="10" confirmDialog={{ confirmDialog }}></optionsForm>
      <confirmDialog></confirmDialog>
      <modelChooser runtimeMode="{{runtimeMode}}" playMode="{{playMode}}"></modelChooser>
      <input id="ntb-import-json"    class="ntb-file-button" type="file" on-change="ntb-import-project" hidden>
      <input id="ntb-import-netlogo" class="ntb-file-button" type="file" on-change="ntb-import-netlogo" hidden>

      <div class="ntb-controls">
        {{# !playMode }}
          <builderMenu
            popupMenu={{ popupMenu }}
            canUndo={{ canUndo }}
            canRedo={{ canRedo }}
            isDebugMode={{ isDebugMode }}
            runtimeMode={{ runtimeMode }}>
          </builderMenu>
        {{/}}

        <tangoDefs
          id="ntb-defs"
          playMode={{ playMode }}
          popupMenu={{ popupMenu }}
          confirmDialog={{ confirmDialog }}
          blockStyles={{ blockStyles }}
          allTags={{ allTags }}
          showCode={{ netTangoToggles.showCode.checked }}
          />

        {{# !playMode }}
          <style id="ntb-injected-css" type="text/css">{{ computedCss }}</style>
        {{/}}
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})

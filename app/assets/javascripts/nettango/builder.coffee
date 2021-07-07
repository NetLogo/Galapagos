import NetTangoBlockDefaults from "./block-defaults.js"
import RactiveCodeMirror from "./code-mirror.js"
import RactiveSpace from "./space.js"
import ObjectUtils from "./object-utils.js"
import newModelNetTango from "./new-model-nettango.js"

getBlockStyleDefaults = (style) ->
  ObjectUtils.clone(NetTango.defaultBlockStyles[style])

isStyleDifferent = (style1, style2) ->
  ["blockColor", "textColor", "borderColor", "fontWeight", "fontSize", "fontFace"]
    .some( (styleProp) -> style1[styleProp] isnt style2[styleProp] )

areStylesDifferent = (bs1, bs2) ->
  ["starterBlockStyle", "containerBlockStyle", "commandBlockStyle"]
    .some( (type) -> isStyleDifferent(bs1[type], bs2[type]) )

tabOptionDefaults = {
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

netTangoToggleDefaults = {
  workspaceBelow: {
    label: "Show NetTango spaces below the NetLogo model"
    checked: false
  },
  showCode: {
    label: "Show the generated NetLogo Code below the NetTango spaces"
    checked: true
  }
}

RactiveBuilder = Ractive.extend({

  data: () -> {
    allTags:          []        # Array[String]
    knownTags:        []        # Array[String]
    breeds:           []        # Array[String]
    playMode:         false     # Boolean
    blockStyles:      undefined # NetTangoBlockStyles
    lastCompiledCode: ""        # String
    spaces:           []        # Array[NetTangoSpace]
    title:            "Blank Model" # String
    tabOptions:       ObjectUtils.clone(tabOptionDefaults)
    netTangoToggles:  ObjectUtils.clone(netTangoToggleDefaults)
    extraCss:         "" # String
  }

  on: {

    'complete': (_) ->
      @observe('spaces', (spaces) ->
        spaces.forEach( (space, i) ->
          space.id      = i
          space.spaceId = "ntb-defs-#{i}"
        )
      )
      return

    # (Context, String, Boolean) => Unit
    '*.ntb-block-code-changed': (_) ->
      @updateCode()
      return

    # (Context, Integer) => Boolean
    '*.ntb-confirm-delete': (context, spaceNumber) ->
      @fire('show-confirm-dialog', context, {
        text: "Do you want to delete this workspace?"
      , approve: {
          text: "Yes, delete the workspace"
        , event: "ntb-delete-blockspace"
        , arguments: [spaceNumber]
        , target: this
        }
      , deny: { text: "No, keep workspace" }
      })
      return false

    '*.ntb-delete-blockspace': (_, spaceNumber) ->
      @deleteSpace(spaceNumber)
      return

    '*.ntb-clear-all-block-styles': (_) ->
      @clearBlockStyles()
      return

    # (Context, DuplicateBlockData) => Unit
    '*.ntb-duplicate-block-to': (_, { fromSpaceId, fromBlockIndex, toSpaceIndex }) ->
      spaces    = @get('spaces')
      fromSpace = spaces.filter( (s) -> s.spaceId is fromSpaceId )[0]
      toSpace   = spaces[toSpaceIndex]
      original  = fromSpace.defs.blocks[fromBlockIndex]
      copy      = NetTangoBlockDefaults.copyBlock(original)

      toSpace.defs.blocks.push(copy)

      @updateNetTango()
      return

    '*.ntb-options-updated': (options) ->
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

      if (areStylesDifferent(NetTango.defaultBlockStyles, options.blockStyles))
        oldStyles = @get("blockStyles")
        if (not oldStyles?) or areStylesDifferent(oldStyles, options.blockStyles)
          @set("blockStyles", options.blockStyles)
          @updateNetTango()
      else
        @set("blockStyles", null)

      @set("extraCss", options.extraCss)

      @refreshCss()
      @set('isSideBySide', not netTangoToggles.workspaceBelow.checked)
      @fire("ntb-options-changed")
      return

  }

  observe: {

    'breeds': () ->
      @initializeTags(@get('knownTags'), @get('spaces'))

  }

  # () => NetTangoBuilderData
  getNetTangoBuilderData: () ->
    spaces = @get('spaces')

    netTangoToggles = { }
    netTangoToggleValues = @get('netTangoToggles')
    Object.getOwnPropertyNames(netTangoToggleValues)
      .forEach((n) -> netTangoToggles[n] = netTangoToggleValues[n].checked)

    tabOptions = { }
    tabOptionValues = @get('tabOptions')
    Object.getOwnPropertyNames(tabOptionValues)
      .forEach((n) -> tabOptions[n] = tabOptionValues[n].checked)

    {
      spaces
    , netTangoToggles
    , tabOptions
    , blockStyles: @get('blockStyles')
    , title:       @get('title')
    , extraCss:    @get('extraCss')
    }

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
      if (c.allowedTags? and ['any-of', 'none-of'].includes(c.allowedTags.type)) then c.allowedTags.tags else []
    )

  # (Array[NetTangoBlock]) -> Array[String]
  getTagsFromBlocks: (blocks) ->
    blocks.flatMap( (b) =>
      blockTags = b.tags ? []
      allowedTags = if (b.allowedTags? and ['any-of', 'none-of'].includes(b.allowedTags.type))
        b.allowedTags.tags
      else
        []
      clauseTags = @getTagsFromClauses(b.clauses ? [])
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

    # Manaully include the observer, since it's not really a breed.  -Jeremy B May 2021
    if not allTags.includes('observer')
      allTags.push('observer')

    @set('allTags', allTags)

    return

  # () => Unit
  resetData: () ->
    @set('allTags',          [])
    @set('knownTags',        [])
    @set('breeds',           [])
    @set('blockStyles',      null)
    @set('lastCompiledCode', "")
    @set('spaces',           [])
    @set('title',            "Blank Model")
    @set('tabOptions',       ObjectUtils.clone(tabOptionDefaults))
    @set('netTangoToggles',  ObjectUtils.clone(netTangoToggleDefaults))
    @set('extraCss',         "")
    return

  # (NetTangoProject) => Unit
  load: (project) ->
    # In case things fail, try not to leave a mess around -Jeremy B July 2021
    @resetData()

    # Make sure styles are loaded first, as when spaces are added
    # they initialize NetTango workspaces with them.  -Jeremy B Jan-2020
    if project.blockStyles? and areStylesDifferent(NetTango.defaultBlockStyles, project.blockStyles)
      blockStyles = {}
      for propName in [ "starterBlockStyle", "containerBlockStyle", "commandBlockStyle" ]
        if project.blockStyles.hasOwnProperty(propName)
          blockStyles[propName] = project.blockStyles[propName]
        else
          blockStyles[propName] = getBlockStyleDefaults(propName)
      @set('blockStyles', blockStyles)
    else
      @set('blockStyles', null)

    @set('spaces', [])
    for spaceVals in (project.spaces ? [])
      @createSpace(spaceVals)
    @updateCode()

    @initializeTags(project["knownTags"] ? [], @get('spaces'))

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
      @fire('ntb-model-change', "New Model", newModelNetTango)

    @refreshCss()
    @set('isSideBySide', not netTangoToggles.workspaceBelow.checked)

    # If this was an import, clear the value so we can re-import the same file in Chrome and Safari - JMB August 2018
    importInput = @find('#ntb-import-json')
    if importInput?
      importInput.value = ''

    return

  clearAll: () ->
    space = {
        id:      0
      , spaceId: "ntb-defs-0"
      , name:    "Block Space 0"
      , width:   430
      , height:  500
      , defs:    { blocks: [], program: { chains: [] } }
    }

    blankData = {
      code:       newModelNetTango
      spaces:     [space]
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
        workspaceBelow: false
        showCode:       true
      }
      extraCss: ""
    }
    @fire("ntb-load-project", {}, blankData)
    return

  # (Boolean) => Unit
  updateCode: () ->
    lastCode    = @get('lastCode')
    newCode     = @assembleCode(displayOnly = false)
    codeChanged = lastCode isnt newCode
    @set('code', @assembleCode(displayOnly = true))
    if codeChanged
      @set('lastCode', newCode)
      @fire('ntb-code-dirty')
    return

  # (Boolean) => String
  assembleCode: (displayOnly) ->
    spaces = @get('spaces')
    spaceCodes =
      spaces.map( (space) ->
        if displayOnly
          prefix = if spaces.length <= 1 then "" else "; Code for #{space.name}\n"
          "#{prefix}#{space.netLogoDisplay ? ""}".trim()
        else
          (space.netLogoCode ? "").trim()
      )
    spaceCodes.join("\n\n")

  # () => NetTangoOptions
  assembleOptions: () ->
    tabOptions      = @get("tabOptions")
    netTangoToggles = @get("netTangoToggles")
    blockStyles     = @get("blockStyles") ? ObjectUtils.clone(NetTango.defaultBlockStyles)
    extraCss        = @get("extraCss")
    options         = {
      tabOptions
    , netTangoToggles
    , blockStyles
    , extraCss
    }
    options

  # (NetTangoSpace) => NetTangoSpace
  createSpace: (spaceVals) ->
    spaces  = @get('spaces')
    id      = spaces.length
    spaceId = "ntb-defs-#{id}"
    defs    = if spaceVals.defs? then spaceVals.defs else { blocks: [], program: { chains: [] } }
    space = {
        id:              id
      , spaceId:         spaceId
      , name:            "Block Space #{id}"
      , width:           430
      , height:          500
      , defs:            defs
    }
    for propName in [ 'name', 'width', 'height' ]
      if(spaceVals.hasOwnProperty(propName))
        space[propName] = spaceVals[propName]

    @push('spaces', space)
    @fire('ntb-space-changed')
    return space

  deleteSpace: (spaceNumber) ->
    spaces    = @get('spaces')
    newSpaces = spaces.filter( (s) -> s.id isnt spaceNumber )
    newSpaces.forEach( (s, i) ->
      s.id      = i
      s.spaceId = "ntb-defs-#{i}"
    )
    @set('spaces', newSpaces)
    @updateCode()
    @fire('ntb-space-changed')
    @fire('ntb-recompile-all')
    return

  # () => Unit
  clearBlockStyles: () ->
    spaces = @findAllComponents("space")
    spaces.forEach( (space) -> space.clearBlockStyles() )
    return

  # () => Unit
  updateNetTango: () ->
    spaces = @findAllComponents("space")
    spaces.forEach( (space) -> space.refreshNetTango(space.get("space"), true) )
    return

  # () => Array[String]
  getProcedures: () ->
    spaces = @findAllComponents("space")
    spaces.flatMap( (space) -> space.getProcedures() )

  components: {
    codeMirror: RactiveCodeMirror
  , space:      RactiveSpace
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-builder">

      <div class="ntb-controls">
        <div class="ntb-block-defs-list">
          {{# spaces }}
          <space
            space="{{ this }}"
            playMode="{{ playMode }}"
            blockStyles="{{ blockStyles }}"
          />
          {{/spaces }}
        </div>

        {{#if !playMode || netTangoToggles.showCode.checked }}
        <label for="ntb-code"{{# !netTangoToggles.showCode.checked }} class="ntb-hide-in-play"{{/}}>NetLogo Code</label>
        <codeMirror
          id="ntb-code"
          mode="netlogo"
          code="{{ code }}"
          config="{ readOnly: 'nocursor' }"
          extraClasses="[ 'ntb-code', 'ntb-code-large', 'ntb-code-readonly' ]"
        />
        {{/if !playMode || netTangoToggles.showCode.checked }}

        {{# !playMode }}
        <style id="ntb-injected-css" type="text/css">{{ computedCss }}</style>
        {{/}}
      </div>
    </div>
    <style id="ntb-injected-style"></style>
    """
    # coffeelint: enable=max_line_length
})

export default RactiveBuilder

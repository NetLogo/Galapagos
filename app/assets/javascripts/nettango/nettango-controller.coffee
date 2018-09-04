class window.NetTangoController

  constructor: (element, localStorage, @overlay, @playMode, @theOutsideWorld) ->
    @firstLoad = true
    @storage = new NetTangoStorage(localStorage)
    Mousetrap.bind(['ctrl+shift+e', 'command+shift+e'], () => @exportNetTango('json'))

    @ractive = @createRactive(element, @theOutsideWorld, @playMode)
    @ractive.on('*.ntb-save',         (_, code)        => @exportNetTango('storage'))
    @ractive.on('*.ntb-recompile',    (_, code)        => @setNetTangoCode(code))
    @ractive.on('*.ntb-model-change', (_, title, code) => @theOutsideWorld.setModelCode(title, code))
    @ractive.on('*.ntb-code-dirty',   (_)              => @markCodeDirty())
    @ractive.on('*.ntb-export-page',  (_)              => @exportNetTango('standalone'))
    @ractive.on('*.ntb-export-json',  (_)              => @exportNetTango('json'))
    @ractive.on('*.ntb-import-json',  (local)          => @importNetTango(local.node.files))
    @ractive.on('*.ntb-load-data',    (_, data)        => @builder.load(data))

  getTestingDefaults: () ->
    if (@playMode)
      Ractive.extend({ })
    else
      RactiveNetTangoTestingDefaults

  createRactive: (element, theOutsideWorld, playMode) ->

    new Ractive({

      el: element,

      data: () -> {
        findElement:   theOutsideWorld.getElementById, # (String) => Element
        createElement: theOutsideWorld.createElement,  # (String) => Element
        appendElement: theOutsideWorld.appendElement,  # (Element) => Unit
        newModel:      theOutsideWorld.newModel,       # () => String
        playMode:      playMode,                       # Boolean
        popupMenu:     undefined                       # RactivePopupMenu
      }

      on: {

        'complete': (_) ->
          popupMenu = @findComponent('popupmenu')
          @set('popupMenu', popupMenu)

          theOutsideWorld.addEventListener('click', (event) ->
            if event?.button isnt 2
              popupMenu.unpop()
          )

          return
      }

      components: {
          popupmenu:       RactivePopupMenu
        , tangoBuilder:    RactiveNetTangoBuilder
        , testingDefaults: @getTestingDefaults()
      },

      template:
        """
        <popupmenu></popupmenu>
        <tangoBuilder
          playMode='{{ playMode }}'
          findElement='{{ findElement }}'
          createElement='{{ createElement }}'
          appendElement='{{ appendElement }}'
          newModel='{{ newModel }}'
          popupMenu='{{ popupMenu }}'
          />
          {{# !playMode }}
            <testingDefaults />
          {{/}}
        """

    })

  # () => Unit
  recompile: () =>
    defs = @ractive.findComponent('tangoDefs')
    defs.recompile()
    return

  # () => Unit
  onModelLoad: () =>
    @builder = @ractive.findComponent('tangoBuilder')
    nt       = @storage.inProgress
    if (nt? and not @playMode and @firstLoad)
      @builder.load(nt)
      @firstLoad = false
    else
      netTangoCodeElement = @theOutsideWorld.getElementById('ntango-code')
      if (netTangoCodeElement? and netTangoCodeElement.textContent? and netTangoCodeElement.textContent isnt '')
        data = JSON.parse(netTangoCodeElement.textContent)
        @builder.load(data)
      else
        @builder.refreshCss()
    return

  # () => Unit
  markCodeDirty: () ->
    @enableRecompileOverlay()
    widgetController = @theOutsideWorld.getWidgetController()
    widgets = widgetController.ractive.get('widgetObj')
    @pauseForevers(widgets)
    return

  # (String) => Unit
  setNetTangoCode: (ntbCode) ->
    widgetController = @theOutsideWorld.getWidgetController()
    oldCode = widgetController.code()
    newCode = NetTangoController.replaceNetTangoCode(oldCode, ntbCode)
    @hideRecompileOverlay()
    widgetController.setCode(newCode, () =>
      widgets = widgetController.ractive.get('widgetObj')
      @rerunForevers(widgets)
    )
    return

  # (String, String) => String
  @replaceNetTangoCode: (oldCode, builderCode) ->
    BEGIN = "; --- NETTANGO BEGIN ---"
    END   = "; --- NETTANGO END ---"
    builderCode = "\n#{BEGIN}\n\n#{builderCode}\n\n#{END}"
    newCode = if (oldCode.indexOf(BEGIN) >= 0)
       oldCode.replace(new RegExp("((?:^|\n)#{BEGIN}\n)([^]*)(\n#{END})"), builderCode)
    else
       oldCode + builderCode
    newCode

  # (Array[File]) => Unit
  importNetTango: (files) ->
    if (not files? or files.length is 0)
      return
    reader = new FileReader()
    reader.onload = (e) =>
      ntData = JSON.parse(e.target.result)
      @builder.load(ntData)
      return
    reader.readAsText(files[0])
    return

  # (String) => Unit
  exportNetTango: (target) ->
    title = @theOutsideWorld.getModelTitle()

    modelCodeMaybe = @theOutsideWorld.getModelCode()
    if(not modelCodeMaybe.success)
      throw new Error("Unable to get existing NetLogo code for replacement")

    netTangoData       = @builder.getNetTangoBuilderData()
    netTangoData.code  = modelCodeMaybe.result
    netTangoData.title = title

    # Always store for 'storage' target - JMB August 2018
    @storeNetTangoData(netTangoData)

    if (target is 'storage')
      return

    if (target is 'json')
      @exportJSON(title, netTangoData)
      return

    # Else target is 'standalone' - JMB August 2018
    parser      = new DOMParser()
    ntPlayer    = new Request('./ntango-play')
    playerFetch = fetch(ntPlayer).then( (ntResp) ->
      if (not ntResp.ok)
        throw Error(ntResp)
      ntResp.text()
    ).then( (text) ->
      parser.parseFromString(text, 'text/html')
    ).then( (exportDom) =>
      @exportStandalone(title, exportDom, netTangoData)
    ).catch((error) =>
      @showError("Unexpected error:  Unable to generate the stand-alone NetTango page.")
    )
    return

  # (String, Document, NetTangoBuilderData) => Unit
  exportStandalone: (title, exportDom, netTangoData) ->
    nlogoCodeElement = exportDom.getElementById('nlogo-code')
    nlogoCodeElement.dataset.filename = title
    nlogoCodeElement.textContent = netTangoData.code

    netTangoCodeElement = exportDom.getElementById('ntango-code')
    # For standalone we don't want the code in the netTango data (it's in the nlogo-code element) - JMB August 2018
    delete netTangoData.code
    netTangoCodeElement.textContent = JSON.stringify(netTangoData)

    styleElement = @theOutsideWorld.getElementById('ntb-injected-style')
    if (styleElement?)
      newElement = exportDom.createElement('style')
      newElement.id = 'ntb-injected-style'
      newElement.innerHTML = @builder.compileCss(true, @builder.get('extraCss'))
      exportDom.head.appendChild(newElement)

    exportWrapper = @theOutsideWorld.createElement('div')
    exportWrapper.appendChild(exportDom.documentElement)
    exportBlob = new Blob([exportWrapper.innerHTML], { type: 'text/html:charset=utf-8' })
    @theOutsideWorld.saveAs(exportBlob, "#{title}.html")
    return

  # (String, NetTangoBuilderData) => Unit
  exportJSON: (title, netTangoData) ->
    filter = (k, v) -> if (k is 'defsJson') then undefined else v
    jsonBlob = new Blob([JSON.stringify(netTangoData, filter)], { type: 'text/json:charset=utf-8' })
    @theOutsideWorld.saveAs(jsonBlob, "#{title}.ntjson")
    return

  # (NetTangoBuilderData) => Unit
  storeNetTangoData: (netTangoData) ->
    set = (prop) => @storage.set(prop, netTangoData[prop])
    [ 'code', 'title', 'extraCss', 'spaces', 'tabOptions' ].forEach(set)
    return

  # () => Unit
  enableRecompileOverlay: () ->
    @overlay.style.display = "flex"
    return

  # () => Unit
  hideRecompileOverlay: () ->
    @overlay.style.display = ""
    return

  # (Array[Widget]) => Unit
  pauseForevers: (widgets) ->
    if not @runningIndices? or @runningIndices.length is 0
      @runningIndices = Object.getOwnPropertyNames(widgets)
        .filter( (index) ->
          widget = widgets[index]
          widget.type is "button" and widget.forever and widget.running
        )
      @runningIndices.forEach( (index) -> widgets[index].running = false )
    return

  # (Array[Widget]) => Unit
  rerunForevers: (widgets) ->
    if @runningIndices? and @runningIndices.length > 0
      @runningIndices.forEach( (index) -> widgets[index].running = true )
    @runningIndices = []
    return

  # (String) => Unit
  showError: (message) ->
    display = @ractive.findComponent('errorDisplay')
    display.show(message)

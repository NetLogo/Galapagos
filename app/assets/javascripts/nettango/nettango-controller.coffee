class window.NetTangoController

  constructor: (element, localStorage, @overlay, @playMode,
    @setModelCode, @getModelElementById, @createElement, @appendElement, @getWidgetController, @saveAs
  ) ->
    @firstLoad = true

    at = @
    @ractive = new Ractive({
      el:       element,

      on: {
        'complete': (_) ->
          popupmenu = @findComponent('popupmenu')
          builder = @findComponent('tangoBuilder')
          builder.setPopupMenu(popupmenu)

          document.addEventListener('click', (event) ->
            if event?.button isnt 2
              popupmenu.unpop()
          )

          Mousetrap.bind(['ctrl+shift+e', 'command+shift+e'], () -> at.exportNetTango('json'))

          return
      }

      data:     () -> {
        findElement:   at.getModelElementById,
        createElement: at.createElement,
        appendElement: at.appendElement,
        playMode:      at.playMode
      }

      components: {
          tangoBuilder:    RactiveNetTangoBuilder
        , testingDefaults: RactiveNetTangoTestingDefaults
        , popupmenu:       RactivePopupMenu
      },

      template:
        """
        <popupmenu></popupmenu>
        <tangoBuilder
          playMode='{{ playMode }}'
          findElement='{{ findElement }}'
          createElement='{{ createElement }}'
          appendElement='{{ appendElement }}'
          />\n
          #{if (@playMode) then '' else '<testingDefaults />'}
        """
    })
    @storage = new NetTangoStorage(localStorage)

    @ractive.on('*.ntb-save',                 (_, code)        => @exportNetTango('storage'))
    @ractive.on('*.ntb-recompile',            (_, code)        => @setNetTangoCode(code))
    @ractive.on('*.ntb-netlogo-code-change',  (_, title, code) => @setModelCode(title, code))
    @ractive.on('*.ntb-code-dirty',           (_)              => @enableRecompileOverlay())
    @ractive.on('*.ntb-export-nettango',      (_)              => @exportNetTango('standalone'))
    @ractive.on('*.ntb-export-nettango-json', (_)              => @exportNetTango('json'))
    @ractive.on('*.ntb-import-nettango-json', (local)          => @importNetTango(local.node.files))
    @ractive.on('*.ntb-load-nettango-data',   (_, data)        => @builder.load(data))

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
      netTangoCodeElement = @getModelElementById('ntango-code')
      if (netTangoCodeElement? and netTangoCodeElement.textContent? and netTangoCodeElement.textContent isnt '')
        data = JSON.parse(netTangoCodeElement.textContent)
        @builder.load(data)
      else
        @builder.refreshCss()
    return

  # (String) => Unit
  setNetTangoCode: (ntbCode) ->
    widgets = @getWidgetController()
    oldCode = widgets.code()
    newCode = NetTangoController.replaceNetTangoCode(oldCode, ntbCode)
    widgets.setCode(newCode)
    @hideRecompileOverlay()
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
    content  = modelContainer.contentWindow ? window
    nlogoRes = content.session.getNlogo()
    if(not nlogoRes.success)
      throw new Error("Unable to get existing NetLogo code for replacement")

    netTangoData       = @builder.getNetTangoBuilderData()
    netTangoData.code  = nlogoRes.result
    netTangoData.title = content.session.modelTitle()

    # always store for 'storage' target
    @storeNetTangoData(netTangoData)

    if (target is 'storage')
      return

    if (target is 'json')
      @exportJSON(netTangoData)
      return

    # else target is 'standalone'
    parser = new DOMParser()
    ntPlayer = new Request('./ntango-play')
    at = @
    playerFetch = fetch(ntPlayer).then((ntResp) ->
      if (ntResp.ok)
        ntResp.text()
    ).then((text) ->
      parser.parseFromString(text, 'text/html')
    ).then((exportDom) ->
      at.exportStandalone(exportDom, netTangoData)
    )
    return

  # (Document, POJO) => Unit
  exportStandalone: (exportDom, netTangoData) ->
    nlogoCodeElement = exportDom.getElementById('nlogo-code')
    nlogoCodeElement.dataset.filename = modelContainer.contentWindow.session.modelTitle()
    nlogoCodeElement.textContent = netTangoData.code

    netTangoCodeElement = exportDom.getElementById('ntango-code')
    # for standalone we don't want the code in the netTango data (it's in the nlogo-code element)
    delete netTangoData.code
    netTangoCodeElement.textContent = JSON.stringify(netTangoData)

    styleElement = @getModelElementById('ntb-injected-style')
    if (styleElement?)
      newElement = exportDom.createElement('style')
      newElement.id = 'ntb-injected-style'
      newElement.innerHTML = @builder.compileCss(true, @builder.get('extraCss'))
      exportDom.head.appendChild(newElement)

    exportWrapper = @createElement('div')
    exportWrapper.appendChild(exportDom.documentElement)
    exportBlob = new Blob([exportWrapper.innerHTML], { type: 'text/html:charset=utf-8' })
    @saveAs(exportBlob, 'ntExportTest.html')
    return

  # (POJO) => Unit
  exportJSON: (netTangoData) ->
    filter = (k, v) -> if (k is 'defsJson') then undefined else v
    jsonBlob = new Blob([JSON.stringify(netTangoData, filter)], { type: 'text/json:charset=utf-8' })
    @saveAs(jsonBlob, 'ntExportTest.json')
    return

  # (POJO) => Unit
  storeNetTangoData: (netTangoData) ->
    at = @
    [ 'code', 'title', 'extraCss', 'spaces', 'tabOptions' ].forEach((prop) ->
      at.storage.set(prop, netTangoData[prop])
    )
    return

  # (Unit) => Unit
  hideRecompileOverlay: () ->
    overlay.style.display = "none"
    return

  # (Unit) => Unit
  enableRecompileOverlay: () ->
    overlay.style.display = "flex"
    return

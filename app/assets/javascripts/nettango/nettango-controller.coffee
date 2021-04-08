class window.NetTangoController

  actionSource: "user"    # "user" | "project-load" | "undo-redo"
  netLogoCode:  undefined # String
  netLogoTitle: undefined # String

  constructor: (element, localStorage, @overlay, @playMode, @runtimeMode, @theOutsideWorld) ->
    @storage      = new NetTangoStorage(localStorage)
    getSpaces     = () => @ractive.findComponent("tangoDefs").get("spaces")
    @isDebugMode  = false
    @rewriter     = new NetTangoRewriter(@getBlocksCode, getSpaces, @isDebugMode)
    @compileAlert = { compileComplete: @netLogoCompileComplete }

    @undoRedo    = new UndoRedo()

    Mousetrap.bind(['ctrl+shift+e', 'command+shift+e'], () => @exportProject('json'))
    Mousetrap.bind(['ctrl+z',       'command+z'      ], () => @undo())
    Mousetrap.bind(['ctrl+y',       'command+shift+z'], () => @redo())

    @ractive = @createRactive(element, @theOutsideWorld, @playMode, @runtimeMode, @isDebugMode, @setDebugMode)

    @ractive.on('*.ntb-recompile',      (_, code)               => @recompileNetLogo(code))
    @ractive.on('*.ntb-model-change',   (_, title, code)        => @setNetLogoCode(title, code))
    @ractive.on('*.ntb-clear-all',      (_)                     => @resetUndoStack())
    @ractive.on('*.ntb-space-changed',  (_)                     => @handleProjectChange())
    @ractive.on('*.ntb-options-changed',(_)                     => @handleProjectChange())
    @ractive.on('*.ntb-undo',           (_)                     => @undo())
    @ractive.on('*.ntb-redo',           (_)                     => @redo())
    @ractive.on('*.ntb-code-dirty',     (_)                     => @markCodeDirty())
    @ractive.on('*.ntb-export-page',    (_)                     => @exportProject('standalone'))
    @ractive.on('*.ntb-export-json',    (_)                     => @exportProject('json'))
    @ractive.on('*.ntb-import-netlogo', (local)                 => @importNetLogo(local.node.files))
    @ractive.on('*.ntb-export-netlogo', (_)                     => @theOutsideWorld.getSession().exportNlogo())
    @ractive.on('*.ntb-load-nl-url',    (_, url, name)          => @theOutsideWorld.loadUrl(url, name))
    @ractive.on('*.ntb-import-project', (local)                 => @importProject(local.node.files))
    @ractive.on('*.ntb-load-sample-project', () =>
      @loadProject(netTangoSampleModel, "project-load"))
    @ractive.on('*.ntb-load-project',   (_, data)               => @loadProject(data, "project-load"))
    @ractive.on('*.ntb-run',            (_, source, command)    =>
      if (@isDebugMode) then console.log("Running:", command)
      session = @theOutsideWorld.getSession()
      if (session?)
        session.widgetController.ractive.fire('run', {}, source, command))

  # (HTMLElement, Environment, Bool) => Ractive
  createRactive: (element, theOutsideWorld, playMode, runtimeMode, isDebugMode, setDebugMode) ->

    new Ractive({

      el: element,

      data: () -> {
        breeds:      []                       # Array[String]
        canRedo:     false                    # Boolean
        canUndo:     false                    # Boolean
        isDebugMode: isDebugMode              # Boolean
        newModel:    theOutsideWorld.newModel # () => String
        playMode:    playMode                 # Boolean
        popupMenu:   undefined                # RactivePopupMenu
        runtimeMode: runtimeMode              # String
      }

      observe: {

        'isDebugMode': () ->
          setDebugMode(@get('isDebugMode'))
          return

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
        , tangoBuilder:    RactiveBuilder
      },

      template:
        """
        <popupmenu></popupmenu>
        <tangoBuilder
          playMode='{{ playMode }}'
          runtimeMode='{{ runtimeMode }}'
          newModel='{{ newModel }}'
          popupMenu='{{ popupMenu }}'
          canUndo='{{ canUndo }}'
          canRedo='{{ canRedo }}'
          breeds={{ breeds }}
          isDebugMode={{ isDebugMode }}
          />
        """

    })

  # (Boolean) => Unit
  setDebugMode: (isDebugMode) =>
    @isDebugMode = isDebugMode
    @rewriter.isDebugMode = isDebugMode
    return

  # () => Array[String]
  getProcedures: () ->
    defs = @ractive.findComponent('tangoDefs')
    defs.getProcedures()

  # () => String
  getBlocksCode: (displayOnly = false) =>
    defs = @ractive.findComponent('tangoDefs')
    defs.assembleCode(displayOnly)

  # This is a debugging method to get a view of the altered code output that
  # NetLogo will compile
  # () => String
  getRewrittenCode: () ->
    code = @theOutsideWorld.getSession().widgetController.code()
    @rewriter.rewriteNetLogoCode(code)

  # () => Unit
  recompile: () =>
    defs = @ractive.findComponent('tangoDefs')
    defs.recompile()
    return

  # Runs any updates needed for old versions, then loads the model normally.
  # If this starts to get more complicated, it should be split out into
  # separate version updates. -Jeremy B October 2019
  # (NetTangoProject, "user" | "project-load" | "undo-redo") => Unit
  loadProject: (project, source) =>
    @actionSource = source
    if (project.code?)
      project.code = NetTangoRewriter.removeOldNetTangoCode(project.code)
    @builder.load(project)
    if (project.netLogoSettings?.isVertical?)
      session = @theOutsideWorld.getSession()
      session.widgetController.ractive.set("isVertical", project.netLogoSettings.isVertical)
    @resetUndoStack()
    @actionSource = "user"
    return

  # () => Unit
  start: (projectUrl) =>
    @builder = @ractive.findComponent('tangoBuilder')
    progress = @storage.inProgress

    # first try to load from the inline code element
    netTangoCodeElement = document.getElementById("ntango-code")
    if (netTangoCodeElement? and netTangoCodeElement.textContent? and netTangoCodeElement.textContent isnt "")
      project = JSON.parse(netTangoCodeElement.textContent)
      @storageId = project.storageId
      if (@playMode and @storageId? and progress? and progress.playProgress? and progress.playProgress[@storageId]?)
        progress = progress.playProgress[@storageId]
        project.spaces = progress.spaces
      @loadProject(project, "project-load")
      return

    # next check the URL parameter
    if (projectUrl?)
      fetch(projectUrl)
      .then( (response) ->
        if (not response.ok)
          throw new Error("#{response.status} - #{response.statusText}")
        response.json()
      )
      .then( (project) =>
        @loadProject(project, "project-load")
      ).catch( (error) =>
        netLogoLoading = document.getElementById("loading-overlay")
        netLogoLoading.style.display = "none"
        error.url = projectUrl
        @ractive.fire('ntb-error', {}, 'load-from-url', error)
        return
      )
      return

    # finally local storage
    if (progress?)
      @loadProject(progress, "project-load")
      return

    # nothing to load, so just refresh and be done
    @builder.refreshCss()
    return

  # () => Unit
  markCodeDirty: () ->
    if @actionSource is "project-load"
      return

    @enableRecompileOverlay()
    widgetController = @theOutsideWorld.getSession().widgetController
    widgets = widgetController.ractive.get('widgetObj')
    @pauseForevers(widgets)
    @spaceChangeListener?()
    return

  # () => Unit
  recompileNetLogo: () ->
    @hideRecompileOverlay()
    widgetController = @theOutsideWorld.getSession().widgetController
    widgetController.ractive.fire('recompile')
    return

  netLogoCompileComplete: () =>
    # if we had any forever buttons running, re-run them
    widgetController = @theOutsideWorld.getSession().widgetController
    widgets          = widgetController.ractive.get('widgetObj')
    @rerunForevers(widgets)

    # breeds may have changed in code, so update for context tags
    workspace  = @theOutsideWorld.getWorkspace()
    breeds     = workspace.breedManager.breeds()
    breedNames = Object.keys(breeds).map( (b) -> breeds[b].originalName )
    ractive.set('breeds', breedNames)
    return

  # (String, String) => Unit
  setNetLogoCode: (title, code) ->
    if (code is @netLogoCode and title is @netLogoTitle)
      return

    @netLogoCode  = code
    @netLogoTitle = title
    @theOutsideWorld.setModelCode(code, title)
    return

  # (Array[File]) => Unit
  importNetLogo: (files) ->
    if (not files? or files.length is 0)
      return
    file   = files[0]
    reader = new FileReader()
    reader.onload = (e) =>
      nlogo = e.target.result
      nlogo = NetTangoRewriter.removeOldNetTangoCode(nlogo)
      @theOutsideWorld.setModelCode(nlogo, file.name)
      @handleProjectChange()
      return
    reader.readAsText(file)
    return

  # (Array[File]) => Unit
  importProject: (files) ->
    if (not files? or files.length is 0)
      return
    reader = new FileReader()
    reader.onload = (e) =>
      project = null
      try
        project = JSON.parse(e.target.result)
      catch error
        @ractive.fire('ntb-error', {}, 'parse-project-json', error)
        return

      @loadProject(project, 'project-load')
      return
    reader.readAsText(files[0])
    return

  # () => NetTangoProject
  getProject: () ->
    session        = @theOutsideWorld.getSession()
    title          = session.modelTitle()
    modelCodeMaybe = session.getNlogo()
    if (not modelCodeMaybe.success)
      @ractive.fire('ntb-error', {}, 'export-nlogo', modelCodeMaybe)

    project       = @builder.getNetTangoBuilderData()
    project.code  = modelCodeMaybe.result
    project.title = title
    isVertical    = session.widgetController.ractive.get("isVertical") ? false
    project.netLogoSettings = { isVertical }
    return project

  handleProjectChange: () ->
    if @actionSource is "project-load"
      return

    project = @getProject()
    @updateUndoStack(project)
    @storeProject(project)

  # () => Unit
  updateCanUndoRedo: () ->
    @ractive.set("canUndo", @undoRedo.canUndo())
    @ractive.set("canRedo", @undoRedo.canRedo())
    return

  # () => Unit
  updateUndoStack: (project) ->
    if @actionSource isnt "user"
      return

    @undoRedo.pushCurrent(project)
    @updateCanUndoRedo()
    return

  # () => Unit
  resetUndoStack: () ->
    if @actionSource is "undo-redo"
      return

    @undoRedo.reset()
    project = @getProject()
    @undoRedo.pushCurrent(project)
    @updateCanUndoRedo()
    @storeProject(project)
    return

  # () => Unit
  undo: () ->
    if (not @undoRedo.canUndo())
      return

    project = @undoRedo.popUndo()
    @updateCanUndoRedo()
    @loadProject(project, "undo-redo")
    return

  # () => Unit
  redo: () ->
    if (not @undoRedo.canRedo())
      return

    project = @undoRedo.popRedo()
    @updateCanUndoRedo()
    @loadProject(project, "undo-redo")
    return

  # (String) => Unit
  exportProject: (target) ->
    project = @getProject()

    # Always store for 'storage' target - JMB August 2018
    @storeProject(project)

    if (target is 'storage')
      return

    if (target is 'json')
      @exportJSON(project.title, project)
      return

    # Else target is 'standalone' - JMB August 2018
    parser      = new DOMParser()
    ntPlayer    = new Request('./nettango-player-standalone')
    playerFetch = fetch(ntPlayer).then( (ntResp) ->
      if (not ntResp.ok)
        throw Error(ntResp)
      ntResp.text()
    ).then( (text) ->
      parser.parseFromString(text, 'text/html')
    ).then( (exportDom) =>
      @exportStandalone(project.title, exportDom, project)
    ).catch( (error) =>
      @ractive.fire('ntb-error', {}, 'export-html', error)
      return
    )
    return

  # () => String
  @generateStorageId: () ->
    "ntb-#{Math.random().toString().slice(2).slice(0, 10)}"

  # (String, Document, NetTangoProject) => Unit
  exportStandalone: (title, exportDom, project) ->
    project.storageId = NetTangoController.generateStorageId()

    netTangoCodeElement = exportDom.getElementById('ntango-code')
    netTangoCodeElement.textContent = JSON.stringify(project)

    exportWrapper = document.createElement('div')
    exportWrapper.appendChild(exportDom.documentElement)
    exportBlob = new Blob([exportWrapper.innerHTML], { type: 'text/html:charset=utf-8' })
    @theOutsideWorld.saveAs(exportBlob, "#{title}.html")
    return

  # (String, NetTangoProject) => Unit
  exportJSON: (title, project) ->
    filter = (k, v) -> if (k is 'defsJson') then undefined else v
    jsonBlob = new Blob([JSON.stringify(project, filter)], { type: 'text/json:charset=utf-8' })
    @theOutsideWorld.saveAs(jsonBlob, "#{title}.ntjson")
    return

  # (NetTangoProject) => Unit
  storeProject: (project) ->
    set = (prop) => @storage.set(prop, project[prop])
    [ 'code', 'title', 'extraCss', 'spaces', 'tabOptions',
      'netTangoToggles', 'blockStyles', 'netLogoSettings' ].forEach(set)
    return

  # () => Unit
  storePlayProgress: () ->
    project                  = @builder.getNetTangoBuilderData()
    playProgress             = @storage.get('playProgress') ? { }
    builderCode              = @getBlocksCode()
    progress                 = { spaces: project.spaces, code: builderCode }
    playProgress[@storageId] = progress
    @storage.set('playProgress', playProgress)
    return

  # (() => Unit) => Unit
  setSpaceChangeListener: (f) ->
    @spaceChangeListener = f
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

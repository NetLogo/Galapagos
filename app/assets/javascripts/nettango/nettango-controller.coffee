import { netTangoEvents } from "./nettango-events.js"

import NetTangoRewriter from "./rewriter.js"
import NetTangoStorage from "./storage.js"
import NetTangoSkeleton from "./nettango-skeleton.js"
import UndoRedo from "./undo-redo.js"

class NetTangoController

  actionSource: "user"    # "user" | "project-load" | "undo-redo"
  netLogoCode:  undefined # String
  netLogoTitle: undefined # String

  constructor: (element, localStorage, @playMode, @runtimeMode, netTangoModelUrl, listeners) ->
    @storage      = new NetTangoStorage(localStorage)
    getSpaces     = () => @builder.get("spaces")
    @isDebugMode  = false
    @rewriter     = new NetTangoRewriter(@getBlocksCode, getSpaces, @isDebugMode)
    @compileAlert = { compileComplete: @netLogoCompileComplete }
    @rewriters    = [@rewriter, @compileAlert]
    @undoRedo     = new UndoRedo()

    Mousetrap.bind(['ctrl+shift+e', 'command+shift+e'], () => @exportProject('json'))
    Mousetrap.bind(['ctrl+z',       'command+z'      ], () => @undo())
    Mousetrap.bind(['ctrl+y',       'command+shift+z'], () => @redo())

    ractive       = NetTangoSkeleton.create(element, @playMode, @runtimeMode, @isDebugMode)
    @ractive      = ractive
    @builder      = @ractive.findComponent('builder')
    @netLogoModel = @ractive.findComponent('netLogoModel')

    @ractive.observe('isDebugMode', (value) =>
      @setDebugMode(value)
      return
    )

    netTangoEvents.forEach( (event) ->
      listeners.forEach( (l) ->
        if l[event]?
          ractive.on("*.#{event}", (_, args...) ->
            l[event](args...)
            return
          )
        return
      )
    )

    @ractive.on('*.ntb-model-change',    (_, title, code) => @setNetLogoCode(title, code))
    @ractive.on('*.ntb-clear-all',       (_)              => @resetUndoStack())
    @ractive.on('*.ntb-space-changed',   (_)              => @handleProjectChange())
    @ractive.on('*.ntb-options-changed', (_)              => @handleProjectChange())
    @ractive.on('*.ntb-undo',            (_)              => @undo())
    @ractive.on('*.ntb-redo',            (_)              => @redo())
    @ractive.on('*.ntb-code-dirty',      (_)              => @recompileProcedures())
    @ractive.on('*.ntb-recompile-all',   (_)              => @recompile())
    @ractive.on('*.ntb-load-variables',  (_)              => @resetBreedsAndVariables())

    @ractive.on('*.ntb-import-netlogo', (local)        => @importNetLogo(local.node.files))
    @ractive.on('*.ntb-export-netlogo', (_)            => @netLogoModel.session.exportNlogo())
    @ractive.on('*.ntb-load-nl-url',    (_, url, name) => @netLogoModel.loadUrl(url, name, @rewriters))

    @ractive.on('*.ntb-import-project',      (local)         => @importProject(local.node.files))
    @ractive.on('*.ntb-load-project',        (_, data)       => @loadProjectData(data))
    @ractive.on('*.ntb-load-remote-project', (_, projectUrl) => @importRemoteProject(projectUrl))

    @ractive.on('*.ntb-export-page', (_) => @exportProject('standalone'))
    @ractive.on('*.ntb-export-json', (_) => @exportProject('json'))

    @ractive.on('complete', (_) => @start(netTangoModelUrl))

  # (Boolean) => Unit
  setDebugMode: (isDebugMode) =>
    @isDebugMode = isDebugMode
    @rewriter.isDebugMode = isDebugMode
    return

  # () => Array[String]
  getProcedures: () ->
    builder = @ractive.findComponent('builder')
    builder.getProcedures()

  # () => String
  getBlocksCode: (displayOnly = false) =>
    builder = @ractive.findComponent('builder')
    builder.assembleCode(displayOnly)

  # () => String
  getNetLogoCode: () ->
    @netLogoModel.widgetController.code()

  # This is a debugging method to get a view of the altered code output that
  # NetLogo will compile
  # () => String
  getRewrittenCode: () ->
    netLogoCode = @getNetLogoCode()
    @rewriter.rewriteNetLogoCode(netLogoCode)

  # (NetTangoProject) => Unit)
  loadProjectData: (data) ->
    @netLogoCode = null
    @loadProject(data, 'project-load')
    return

  # Runs any updates needed for old versions, then loads the model normally.
  # If this starts to get more complicated, it should be split out into
  # separate version updates. -Jeremy B October 2019
  # (NetTangoProject, "user" | "project-load" | "undo-redo") => Unit
  loadProject: (project, source) =>
    @actionSource = source
    if project.code?
      project.code = NetTangoRewriter.removeOldNetTangoCode(project.code)

    if project.tabOptions?
      project.netLogoOptions = project.tabOptions
      delete project.tabOptions

    if project.netTangoToggles?
      project.netTangoOptions = project.netTangoToggles
      delete project.netTangoToggles

    @builder.load(project)
    if project.netLogoSettings?.isVertical?
      @netLogoModel.widgetController.ractive.set("isVertical", project.netLogoSettings.isVertical)
    @resetUndoStack()
    @actionSource = "user"
    return

  # () => Unit
  start: (projectUrl) =>
    progress = @storage.inProgress

    # first try to load from the inline code element
    netTangoCodeElement = document.getElementById("nettango-code")
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
      @importRemoteProject(projectUrl)
      return

    # finally local storage
    if (progress?)
      @loadProject(progress, "project-load")
      return

    # nothing to load, so just refresh and be done
    @builder.refreshCss()
    return

  # () => Unit
  recompileProcedures: () ->
    if @actionSource is "project-load"
      return

    widgetController = @netLogoModel.widgetController
    if widgetController.ractive.get('lastCompileFailed')
      @recompile()

    else
      proceduresCode = @getBlocksCode()
      procedureNames = @getProcedures()

      widgets = widgetController.ractive.get('widgetObj')
      @pauseForevers(widgets)
      widgetController.ractive.fire('recompile-procedures', proceduresCode, procedureNames, @netLogoCompileComplete)
      @spaceChangeListener?()
      return

  # () => Unit
  recompile: () ->
    widgetController = @netLogoModel.widgetController
    widgets = widgetController.ractive.get('widgetObj')
    @pauseForevers(widgets)
    widgetController.ractive.fire('recompile-sync', 'system')
    @spaceChangeListener?()
    return

  netLogoCompileComplete: () =>

    # if we had any forever buttons running, re-run them
    widgetController = @netLogoModel.widgetController
    widgets          = widgetController.ractive.get('widgetObj')
    @rerunForevers(widgets)

    @resetBreedsAndVariables()

    return

  resetBreedsAndVariables: () ->
    # breeds may have changed in code, so update for context tags
    workspace = @netLogoModel.workspace

    if workspace is null
      return

    breedsObject     = workspace.breedManager.breeds()
    breeds           = Object.keys(breedsObject).map( (breedName) -> breedsObject[breedName] )
    turtleBreedNames = breeds.filter( (b) -> not b.isLinky() ).map( (b) -> b.originalName )
    linkBreedNames   = breeds.filter( (b) -> b.isLinky()     ).map( (b) -> b.originalName )
    allAgentTypes    = turtleBreedNames.concat(linkBreedNames).concat(['patches'])
    ractive.set('breeds', allAgentTypes)

    compiler = @netLogoModel.session.compiler

    globalVariables = compiler.listGlobalVars().map( (global) -> { name: global.name, tags: [] })

    # The `badTypes` arrays contain the variables which will never have a type usable in a
    # NetTango expression (Number or Boolean).  It's not ideal to hardcode them like this,
    # but it's simple, works, and these don't change very often.  -Jeremy B September 2021

    makeBuiltInVars = (vars, tags, badTypes) ->
      vars.filter(
        (v) -> not badTypes.includes(v)
      ).map(
        (v) -> { name: v, tags: tags }
      )

    makeBreedVars = (breedNames, getVarsForBreed) ->
      breedNames.map( (breedName) ->
        tags = [breedName]
        getVarsForBreed(breedName).map( (breedVar) -> { name: breedVar, tags: tags })
      )

    patchVariables = makeBuiltInVars(compiler.listPatchVars(), ['patches', 'turtles'], ['plabel'])

    turtleBreedVariables = makeBreedVars(turtleBreedNames, (bn) -> compiler.listOwnVarsForBreed(bn))
    badTypes             = ['breed', 'label', 'shape']
    turtleVariables      = makeBuiltInVars(compiler.listTurtleVars(), turtleBreedNames, badTypes)

    linkBreedVariables = makeBreedVars(linkBreedNames, (bn) -> compiler.listLinkOwnVarsForBreed(bn))
    badTypes           = ['breed', 'end1', 'end2', 'label', 'shape', 'tie-mode']
    linkVariables      = makeBuiltInVars(compiler.listLinkVars(), linkBreedNames, badTypes)

    otherVariables = [globalVariables, patchVariables, turtleVariables, linkVariables]
    variables      = turtleBreedVariables.concat(linkBreedVariables).concat(otherVariables).flat()
    ractive.set('variables', variables)
    return

  # (String, String) => Unit
  setNetLogoCode: (title, code) ->
    if (code is @netLogoCode and title is @netLogoTitle)
      return

    @netLogoCode  = code
    @netLogoTitle = title
    @netLogoModel.loadModel(code, title, @rewriters)
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
      @netLogoModel.loadModel(nlogo, file.name, @rewriters)
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
        @ractive.fire('nettango-error', {}, 'parse-project-json', error)
        return

      @loadProjectData(project)
      return
    reader.readAsText(files[0])
    return

  importRemoteProject: (projectUrl) ->
    netLogoLoading = document.getElementById("loading-overlay")
    netLogoLoading.style.display = ""
    fetch(projectUrl)
    .then( (response) ->
      if (not response.ok)
        throw new Error("#{response.status} - #{response.statusText}")
      response.json()
    )
    .then( (project) =>
      @loadProjectData(project)
    ).catch( (error) =>
      netLogoLoading.style.display = "none"
      error.url = projectUrl
      @ractive.fire('nettango-error', {}, 'load-from-url', error)
      return
    )
    return

  # () => NetTangoProject
  getProject: () ->
    session        = @netLogoModel.session
    title          = session.modelTitle()
    modelCodeMaybe = session.getNlogo()
    if (not modelCodeMaybe.success)
      @ractive.fire('nettango-error', {}, 'export-nlogo', modelCodeMaybe)

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
    return

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
      @ractive.fire('nettango-error', {}, 'export-html', error)
      return
    )
    return

  # () => String
  @generateStorageId: () ->
    "ntb-#{Math.random().toString().slice(2).slice(0, 10)}"

  # (String, Document, NetTangoProject) => Unit
  exportStandalone: (title, exportDom, project) ->
    project.storageId = NetTangoController.generateStorageId()

    netTangoCodeElement = exportDom.getElementById('nettango-code')
    netTangoCodeElement.textContent = JSON.stringify(project)

    exportWrapper = document.createElement('div')
    exportWrapper.appendChild(exportDom.documentElement)
    exportBlob = new Blob([exportWrapper.innerHTML], { type: 'text/html:charset=utf-8' })
    window.saveAs(exportBlob, "#{title}.html")
    return

  # (String, NetTangoProject) => Unit
  exportJSON: (title, project) ->
    filter = (k, v) -> if (k is 'defsJson') then undefined else v
    jsonBlob = new Blob([JSON.stringify(project, filter)], { type: 'text/json:charset=utf-8' })
    window.saveAs(jsonBlob, "#{title}.ntjson")
    return

  # (NetTangoProject) => Unit
  storeProject: (project) ->
    set = (prop) => @storage.set(prop, project[prop])
    [ 'code', 'title', 'extraCss', 'spaces', 'netLogoOptions',
      'netTangoOptions', 'blockStyles', 'netLogoSettings' ].forEach(set)
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

export default NetTangoController

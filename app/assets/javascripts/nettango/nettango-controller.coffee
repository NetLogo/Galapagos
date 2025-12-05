import { createCommonArgs, createNamedArgs } from "../notifications/listener-events.js"
import { netTangoEvents } from "./nettango-events.js"

import { NamespaceStorage } from "../namespace-storage.js"

import NetTangoRewriter from "./rewriter.js"
import newModelNetTango from "./new-model-nettango.js"
import { NETTANGO_PROJECT_VERSION, createNewProject } from "./nettango-data.js"
import NetTangoSkeleton from "./nettango-skeleton.js"
import UndoRedo from "./undo-redo.js"

class NetTangoController

  actionSource: "user"    # "user" | "project-load" | "undo-redo"
  netLogoCode:  undefined # String
  netLogoTitle: undefined # String

  constructor: (element, locale, localStorage, @playMode, @runtimeMode,
    @disableAutoStore, netTangoModelUrl, listeners) ->

    @storage = new NamespaceStorage('ntInProgress', localStorage)
    if @storage.wasFirstInstance
      @storeProject(createNewProject())

    @autoStorePlay = @playMode and not @disableAutoStore
    getSpaces      = () => @builder.get("spaces")
    @isDebugMode   = false
    @rewriter      = new NetTangoRewriter(@getBlocksCode, getSpaces, @isDebugMode)
    @compileAlert  = { compileComplete: @netLogoCompileComplete }
    @rewriters     = [@rewriter, @compileAlert]
    @undoRedo      = new UndoRedo()

    Mousetrap.bind(['ctrl+shift+e', 'command+shift+e'], () => @exportProject('json'))
    Mousetrap.bind(['ctrl+z',       'command+z'      ], () => @undo())
    Mousetrap.bind(['ctrl+y',       'command+shift+z'], () => @redo())

    ractive       = NetTangoSkeleton.create(element, locale, @playMode, @runtimeMode, @isDebugMode)
    @ractive      = ractive
    @builder      = @ractive.findComponent('builder')
    @netLogoModel = @ractive.findComponent('netLogoModel')
    @netLogoModel.rewriters = @rewriters

    @ractive.observe('isDebugMode', (value) =>
      @setDebugMode(value)
      return
    )

    netTangoEvents.forEach( (event) ->
      listeners.forEach( (l) ->
        if l[event.name]?
          ractive.on("*.#{event.name}", (_, args...) ->
            commonArgs = createCommonArgs()
            eventArgs  = createNamedArgs(event.args, args)
            l[event.name](commonArgs, eventArgs)
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

    @ractive.on('*.ntb-import-netlogo', (local)  => @importNetLogo(local.node.files))
    @ractive.on('*.ntb-export-netlogo', (_)      => @netLogoModel.session.exportNlogoXML())
    @ractive.on('*.ntb-load-nl-url',    (_, url) => @netLogoModel.loadUrl(url))

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
    @netLogoModel.oracle.getCode()

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
      if (
        @autoStorePlay and
        @storageId? and
        progress? and progress.playProgress? and progress.playProgress[@storageId]?
      )
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

      widgetController.pauseForevers()
      # coffeelint: disable=max_line_length
      widgetController.ractive.fire('recompile-procedures', proceduresCode, procedureNames, widgetController.rerunForevers)
      # coffeelint: enable=max_line_length
      @spaceChangeListener?()
      return

  # () => Unit
  recompile: () ->
    widgetController = @netLogoModel.widgetController
    widgetController.pauseForevers()
    widgetController.ractive.fire('recompile-sync', 'system')
    @spaceChangeListener?()
    return

  netLogoCompileComplete: () =>
    # if we had any forever buttons running, re-run them
    @netLogoModel.widgetController.rerunForevers()
    # breeds and variables may have changed in code, so update for context tags and variables
    @resetBreedsAndVariables()
    return

  resetBreedsAndVariables: () ->
    oracle = @netLogoModel.oracle

    if not oracle?
      return

    turtleBreedNames = oracle.getTurtleBreeds()
    linkBreedNames   = oracle.getLinkBreeds()
    allAgentTypes    = turtleBreedNames.concat(linkBreedNames).concat(['patches'])

    ractive.set('breeds', allAgentTypes)

    globalVariables = oracle.getGlobals().map( (global) -> { name: global.name, tags: [] })

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

    patchVariables = makeBuiltInVars(oracle.getPatchVars(), ['patches', 'turtles'], ['plabel'])

    turtleBreedVariables = makeBreedVars(turtleBreedNames, (bn) -> oracle.getTurtleBreedVars(bn))
    badTypes             = ['breed', 'label', 'shape']
    turtleVariables      = makeBuiltInVars(oracle.getTurtleVars(), turtleBreedNames, badTypes)

    linkBreedVariables = makeBreedVars(linkBreedNames, (bn) -> oracle.getLinkBreedVars(bn))
    badTypes           = ['breed', 'end1', 'end2', 'label', 'shape', 'tie-mode']
    linkVariables      = makeBuiltInVars(oracle.getLinkVars(), linkBreedNames, badTypes)

    otherVariables = [globalVariables, patchVariables, turtleVariables, linkVariables]
    variables      = turtleBreedVariables.concat(linkBreedVariables).concat(otherVariables).flat()
    ractive.set('variables', variables)
    return

  # (String, String) => Unit
  setNetLogoCode: (title, code) ->
    if (code is @netLogoCode and title is @netLogoTitle)
      return

    @netLogoTitle = title

    if code.trim().startsWith("<?xml")
      @netLogoModel.loadXMLModel(code, 'script-element', "#{title}.nlogox")
      @netLogoCode = code
    else
      @netLogoModel.loadOldFormatModel(code, 'script-element', "#{title}.nlogo")
      @netLogoCode = @netLogoModel.oracle.getNlogo()

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
      if nlogo.trim().startsWith("<?xml")
        @netLogoModel.loadXMLModel(nlogo, 'disk', file.name)
      else
        @netLogoModel.loadOldFormatModel(nlogo, 'disk', file.name)
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
    oracle     = @netLogoModel.oracle
    title      = oracle.getModelTitle()
    nlogoMaybe = oracle.getNlogo()
    if (not nlogoMaybe.success)
      @ractive.fire('nettango-error', {}, 'export-nlogo', nlogoMaybe)

    project                 = @builder.getNetTangoBuilderData()
    project.code            = nlogoMaybe.result
    project.title           = title
    project.projectVersion  = NETTANGO_PROJECT_VERSION
    isVertical              = oracle.getSetting("isVertical") ? false
    project.netLogoSettings = { isVertical }
    project

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
      'netTangoOptions', 'blockStyles', 'netLogoSettings', 'projectVersion' ].forEach(set)

    if @autoStorePlay
      @storePlayProgress()

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

export default NetTangoController

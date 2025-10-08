import { newCustomModel } from "/new-model.js"
import generateHNWConfig from './hnw-config-file-generator.js'

import { nlogoXMLToDoc, docToNlogoXML, stripXMLCdata } from "./tortoise-utils.js"

lastWrangler = null # TextWrangler
promiseID    = 0    # Number

# type Entry = { frame :: IFrame, message :: Object[Any], callback :: () => Unit }
queue      = undefined # Array[Entry]
intervalID = undefined # Number

class XMLTextWrangler
  constructor: (@modelText) ->
    try
      @doc     = nlogoXMLToDoc(@modelText)
      @isValid = ["code", "info", "widgets"].every( (element) => @doc.querySelector(element) isnt null )

    catch ex
      @isValid = false

  checkValidity: () ->
    [@isValid, "Invalid '.nlogox' file; not an XML file or missing necessary sections"]

  getCode: () ->
    stripXMLCdata(@doc.querySelector("code").innerHTML)

  withCode: (code) ->
    newDoc                = nlogoXMLToDoc(@modelText)
    codeElement           = newDoc.querySelector("code")
    codeElement.innerHTML = "<![CDATA[#{code}]]>"
    newSource             = docToNlogoXML(newDoc)
    new XMLTextWrangler(newSource)

  compile: (compiler) ->
    compiler.fromNlogoXML(@modelText)

params = Object.fromEntries(new URLSearchParams(window.location.search).entries())

if params.embedded is "true"
  document.querySelector(".topbar").classList.add("hidden")

# (File) => Promise[String]
readFile = (file) ->
  reader = new FileReader()
  new Promise(
    (resolve, reject) ->
      reader.onerror = ->
        reader.abort()
        reject(new DOMException("Unable to parse file."))
      reader.onload = ->
        resolve(reader.result)
      reader.readAsText(file)
  )

# (Window, Any, () => Unit) => Unit
postWhenReady = (frame, message, callback = (->)) ->
  queue.push({ frame, message, callback })
  if not intervalID?
    startInterval()
  return

document.getElementById("start-over-button").onclick = ->
  if confirm("You will lose all of your unsaved changes.  Continue?")
    document.getElementById("mode-controls" ).classList.remove("hidden")
    document.getElementById("config-content").classList.add(    "invis")
    cancelInterval()

# () => Unit
document.getElementById("from-scratch-button").onclick = ->

  newCode =
    """
    breed [ students student ]

    to setup
    end

    to go
    end
    """.trim()

  modelText        = newCustomModel(newCode)
  config           = generateHNWConfig(modelText)
  config.onIterate = "go"
  config.onStart   = "setup"

  initialize(modelText, config)

  return

# () => Unit
document.getElementById("without-config-button").onclick = ->

  input = document.getElementById("without-config-model-input")

  input.onchange = ->
    form     = document.getElementById("without-config-form")
    formData = new FormData(form)
    model    = formData.get('model-without-config')
    readFile(model).then(
      (modelText) ->
        finalText = if modelText.trim().startsWith("<?xml")
          modelText
        else
          compiler = new BrowserCompiler()
          oldFormatResult = compiler.convertNlogoToXML(modelText)
          if (not oldFormatResult.success)
            console.log(oldFormatResult)
            # coffeelint: disable=max_line_length
            err = "Failed to convert old format model to XML.  Make sure the model is a valid NetLogo 6 or 7 model.  The converter gave the error:  #{oldFormatResult.result[0].message}"
            # coffeelint: enable=max_line_length
            alert(new Error(err))

          oldFormatResult.result

        config = generateHNWConfig(finalText)
        initialize(finalText, config)
    )
    input.value = ""

  input.click()

  return

# () => Unit
document.getElementById("config-nlogo-button").onclick = ->

  baseInput   = document.getElementById("base-model-input")
  configInput = document.getElementById("config-input")

  configInput.onchange = ->

    form          = document.getElementById("config-form")
    formData      = new FormData(form)
    baseModelFile = formData.get('base-model')
    configFile    = formData.get('config')

    Promise.all([baseModelFile, configFile].map(readFile)).then(
      ([baseModelText, configText]) ->
        compiler = new BrowserCompiler()
        oldFormatResult = compiler.convertNlogoToXML(baseModelText)
        if (not oldFormatResult.success)
          console.log(oldFormatResult)
          # coffeelint: disable=max_line_length
          err = "Failed to convert old format model to XML.  Make sure the model is a valid NetLogo 6 or 7 model.  The converter gave the error:  #{oldFormatResult.result[0].message}"
          # coffeelint: enable=max_line_length
          alert(new Error(err))

        config = JSON.parse(configText)
        initialize(oldFormatResult.result, config)
    )

    baseInput  .value = ""
    configInput.value = ""

  baseInput.click()
  configInput.click()

  return

# () => Unit
document.getElementById("config-bundle-button").onclick = ->

  bundleInput = document.getElementById("config-bundle-input")

  bundleInput.onchange = ->

    form       = document.getElementById("bundle-form")
    formData   = new FormData(form)
    bundleFile = formData.get('bundle')

    readFile(bundleFile).then(
      (bundleText) ->

        [nlogox, config] = if bundleText.trim().startsWith("<?xml")
          nlogoDoc         = nlogoXMLToDoc(bundleText)
          hnwConfigElement = nlogoDoc.querySelector("hubnet-web-config")
          configJson       = stripXMLCdata(hnwConfigElement.innerHTML)
          [bundleText, JSON.parse(configJson)]

        else
          bundle = JSON.parse(bundleText)

          if bundle.hnwNlogo?
            nlogo        = bundle.hnwNlogo
            delete bundle.hnwNlogo
            compiler     = new BrowserCompiler()
            nlogoxResult = compiler.convertNlogoToXML(nlogo)
            if not nlogoxResult.success
              console.log(nlogoxResult)
              throw new Error("Failed to convert old format model to NetLogo 7 format.")

            [nlogoxResult.result, bundle]

        initialize(nlogox, config)
        bundleInput.value = ""

    )

  bundleInput.click()

  return

# (String) => Unit
initializeRole = (roleName) ->

  configFrameContainer = document.getElementById('config-frames')
  tabButtonContainer   = document.getElementById('config-tab-buttons')
  configTemplate       = document.getElementById('config-template')
  tabButtonTemplate    = document.getElementById('tab-button-template')
  addRoleButton        = document.getElementById('add-role-button')

  roleConfig             = configTemplate.content.cloneNode(true)
  frame                  = roleConfig.querySelector('iframe')
  frame.dataset.roleName = roleName
  configFrameContainer.appendChild(roleConfig)

  tabButton              = tabButtonTemplate.content.cloneNode(true)
  tabButtonInput         = tabButton.querySelector('input')
  tabButtonInput.value   = roleName
  tabButtonInput.onclick = -> selectConfigTab(tabButtonInput)
  tabButtonContainer.appendChild(tabButton)

  # Move it to the end, if it isn't already in limbo --Jason B. (6/21)
  if addRoleButton?
    tabButtonContainer.appendChild(addRoleButton)

  return

# (String, String) => Unit
initialize = (modelText, config) ->

  wrangler = new XMLTextWrangler(modelText)

  [isValid, error] = wrangler.checkValidity()

  if isValid

    lastWrangler = wrangler

    document.getElementById("mode-controls"    ).classList.add(   "hidden")
    document.getElementById('config-content'   ).classList.remove("invis")

    configFrameContainer = document.getElementById('config-frames')
    tabButtonContainer   = document.getElementById('config-tab-buttons')
    codeFrame            = document.getElementById('code-frame')
    codeTabButton        = document.getElementById('code-tab-button')
    addRoleButton        = document.getElementById('add-role-button')

    configFrameContainer.innerHTML = ''
    configFrameContainer.appendChild(codeFrame)

    tabButtonContainer.innerHTML = ''
    tabButtonContainer.appendChild(codeTabButton)

    config.roles.forEach((role) -> initializeRole(role.name))

    tabButtonContainer.appendChild(addRoleButton)

    selectConfigTab(codeTabButton)

    reinitialize(wrangler, config)

  else
    alert(new Error(error))

  return

# (XMLTextWrangler, String) => Unit
reinitialize = (wrangler, config) ->

  ids = ["download-nlogox-button", "start-over-button"]
  ids.forEach((id) -> document.getElementById(id).disabled = false)

  [isValid, error] = wrangler.checkValidity()
  if isValid

    lastWrangler = wrangler

    codeFrame = document.getElementById('code-frame')

    postWhenReady(codeFrame, {
      code: wrangler.getCode()
    , type: "import-code"
    })

    compiler = new BrowserCompiler()
    result   = wrangler.compile(compiler)

    document.getElementById('test-model-button').disabled = not result.model.success

    compiler =
      if result.model.success
        compiler
      else
        msg = result.model.result.map((x) -> x.message).join('\n')
        alert(new Error("Model did not compile:\n\n#{msg}"))
        lastSuccessfulCompiler or {
          listGlobalVars:   (-> [])
        , listProcedures:   (-> [])
        , listVarsForBreed: (-> [ 'breed', 'color', 'heading', 'hidden?', 'label', 'label-color'
                                , 'pen-mode', 'pen-size', 'shape', 'size', 'who', 'xcor', 'ycor'])
        }

    globals    = compiler.listGlobalVars()
    procedures = compiler.listProcedures()

    pluckMain = (configValue, procs, term) ->
      if configValue? and configValue isnt ""
        configValue.toLowerCase()
      else if procs.some((p) -> p.name.toLowerCase() is term)
        term
      else
        ""

    onSetup = pluckMain(config.onStart  , procedures, "setup")
    onGo    = pluckMain(config.onIterate, procedures,    "go")

    postWhenReady(codeFrame, {
      procedures
    , onGo
    , onSetup
    , targetFrameRate: config.targetFrameRate
    , type:            "import-procedures"
    })

    config.roles.forEach((role) ->

      frame = document.querySelector("iframe[data-role-name=\"#{role.name}\"]")

      globalVars =
        globals.filter((g) -> g.type is "user" and not g.name.startsWith("__hnw_"))

      myVars =
        if role.isSpectator
          slug = "__hnw_#{role.name}_"
          vars = globals.filter((g) -> g.type is "user" and g.name.startsWith(slug))
          vars.map((v) -> v.name.slice(slug.length))
        else
          compiler.listVarsForBreed(role.namePlural)

      postWhenReady(frame, { globalVars
                           , myVars
                           , procedures
                           , role
                           , type: "config-with-json" })

      lastSuccessfulCompiler = compiler

      return

    )

  else
    alert(new Error(error))

  return

# (DOMElement) => Unit
selectConfigTab = (elem) ->

  configFrameContainer = document.getElementById('config-frames')
  tabButtonContainer   = document.getElementById('config-tab-buttons')

  cfcs = Array.from(configFrameContainer.children)
  tbcs = Array.from(tabButtonContainer  .children)

  cfcs.forEach((child) -> child.classList.add('invis'); child.classList.remove('vis'))
  tbcs.forEach((child) -> child.classList.remove('selected'))

  index = Array.from(tabButtonContainer.children).findIndex((x) -> x is elem)
  selectedConfig = Array.from(configFrameContainer.children)[index]
  selectedConfig.classList.remove('invis')
  selectedConfig.classList.add('vis')
  elem.classList.add('selected')

  return

ctb         = document.getElementById("code-tab-button")
ctb.onclick = -> selectConfigTab(ctb)

# (String, String) => Unit
document.getElementById("add-role-button").onclick = ->

  roleSingular = prompt("Role name (singular)?")

  sibilant     = roleSingular.endsWith("s")
  autoPlural   = "#{roleSingular}#{if sibilant then "e" else ""}s"
  rolePlural   = prompt("Role name (plural)?", autoPlural)

  if roleSingular isnt "" and rolePlural isnt "" and roleSingular isnt rolePlural
    if roleSingular? and rolePlural?

      initializeRole(roleSingular)

      dummyView =
        { "x": 162, "y": 43, "height": 429, "width": 429, "type": "hnwView" }

      dummyConfig =
        { afterDisconnect:    null
        , canJoinMidRun:      true
        , onCursorMove:       null
        , onCursorClick:      null
        , onDisconnect:       null
        , widgets:            [dummyView]
        , name:               roleSingular
        , namePlural:         rolePlural
        , onConnect:          null
        , perspectiveVar:     null
        , viewOverrideVar:    null
        , highlightMainColor: "#008000"
        , limit:              -1
        , isSpectator:        false
        }

      parcel =
        { type:       "config-with-json"
        , globalVars: []
        , myVars:     []
        , procedures: []
        , role:       dummyConfig
        }

      myFrame = document.querySelector(".model-container[data-role-name='#{roleSingular}']")

      oldCode     = lastWrangler.getCode()
      regex       = new RegExp("^\\s*breed\\s*\\[\\s*#{rolePlural}\\s+")
      breedExists = regex.test(oldCode)

      postWhenReady(myFrame, parcel, (-> if not breedExists then recompile()))

      if not breedExists

        beforeFirstProcedureRegex = new RegExp("(.*?)^((?:^ *;.*?)*(?:to |to-report ).*)", "ms")
        breedDeclaration          = "breed [ #{rolePlural} #{roleSingular} ]"

        newCode = if beforeFirstProcedureRegex.test(oldCode)
          oldCode.replace(beforeFirstProcedureRegex, "$1#{breedDeclaration}\n\n$2")
        else
          "#{oldCode}\n\n#{breedDeclaration}"
        lastWrangler = lastWrangler.withCode(newCode)

  else
    addRole()

  return

# (Window) => (Object[Any]) => Promise[Any]
postPromise = (target) -> (message) ->
  new Promise(
    (resolve, reject) ->
      myID     = promiseID++
      listener = window.addEventListener("message", (e) ->
        if e.data.identifier is myID
          window.removeEventListener("message", listener)
          resolve(e.data.parcel)
      , false)
      target.contentWindow.postMessage(Object.assign({}, message, { identifier: myID }), '*')
  )

# (String) => (String) => Unit
download = (filename) -> (content) ->

  elem = document.createElement('a')
  elem.setAttribute('href', "data:text/plain;charset=utf-8,#{encodeURIComponent(content)}")
  elem.setAttribute('download', filename)

  elem.style.display = 'none'
  document.body.appendChild(elem)

  elem.click()

  document.body.removeChild(elem)

  return

# () => Promise[Config]
genConfigP = ->

  codeFrame  = document.getElementById('code-frame')
  frames     = [codeFrame].concat(Array.from(document.querySelectorAll(".config-container")))
  promises   = frames.map((frame) -> postPromise(frame)({ type: "request-save" }))

  Promise.all(promises).then(
    ([codeFrameConfig, roles...]) ->
      { onIterate:       codeFrameConfig.onGo
      , onStart:         codeFrameConfig.onSetup
      , targetFrameRate: codeFrameConfig.targetFrameRate
      , roles
      , type:            "hubnet-web"
      , version:         "hnw-alpha-1"
      }
  )

# () => Promise[(String, String)]
requestNlogoxAndJSON = ->

  codeFrame = document.getElementById('code-frame')

  nlogoxPromise =
    postPromise(codeFrame)({ type: "request-save" }).then(
      ({ code }) ->
        lastWrangler.withCode(code).modelText
    )

  configPromise = genConfigP().then((outConfig) -> JSON.stringify(outConfig))

  Promise.all([nlogoxPromise, configPromise])

class HubNetWebConfigElement extends HTMLElement
  constructor: ->
    super()

customElements.define("hubnet-web-config", HubNetWebConfigElement)

# () => Unit
document.getElementById("download-nlogox-button").onclick = ->

  filename = prompt("Enter file name (without file extension):", "")

  if filename?

    nlogoxName = if filename.endsWith(".nlogox") then filename else "#{filename}.nlogox"

    requestNlogoxAndJSON().then(
      ([nlogox, json]) ->
        nlogoDoc     = nlogoXMLToDoc(nlogox)
        modelElement = nlogoDoc.querySelector("model")

        existingConfig = modelElement.querySelector("hubnet-web-config")
        if existingConfig? then modelElement.removeChild(existingConfig)

        hnwConfigElement           = new HubNetWebConfigElement()
        hnwReplaceString           = "{{{HUBNET-WEB-CONFIG-REPLACEMENT}}}"
        hnwConfigElement.innerHTML = hnwReplaceString
        modelElement.appendChild(hnwConfigElement)

        hnwNlogoxUnfixed = docToNlogoXML(nlogoDoc)

        # Web browsers don't like CDATA in their HTML documents, so they turn them into HTML comments.  This is enough
        # to get them back into a proper form for the NetLogo Web parser.  -Jeremy B Octover 2025
        hnwNlogox = hnwNlogoxUnfixed.replace(hnwReplaceString, "<![CDATA[#{json}]]>")
        download(nlogoxName)(hnwNlogox)
    )

  return

# () => Unit
document.getElementById("edit-model-button").onclick = ->
  configFrame    = document.getElementById("config-content-frame")
  outerTestFrame = document.getElementById("outer-test-frame")
  contentDiv     = document.querySelector(".content")
  configFrame   .classList.remove('invis')
  outerTestFrame.classList.   add('invis')
  contentDiv    .classList.remove('full-height')
  return

# () => Unit
document.getElementById("test-model-button").onclick = ->

  sessionName = ""

  while sessionName is ""

    sessionName = prompt("Session name?")

    if sessionName isnt "" and sessionName?

      password = prompt("Session password?")

      if password?

        requestNlogoxAndJSON().then(
          ([nlogox, config]) ->

            parcel                = { type: "galapagos-direct-launch", nlogox, config, sessionName, password }
            innerTestFrame        = document.getElementById("inner-test-frame")
            innerTestFrame.onload = -> innerTestFrame.contentWindow.postMessage(parcel, "*")
            innerTestFrame.src    = "//#{window.location.hostname}:8080/host?embedded=true"

            configFrame    = document.getElementById("config-content-frame")
            outerTestFrame = document.getElementById("outer-test-frame")
            contentDiv     = document.querySelector(".content")
            configFrame   .classList.   add('invis')
            outerTestFrame.classList.remove('invis')
            contentDiv    .classList.   add('full-height')

        )

  return

addNewBreedVar = (breedName, varName) ->

  oldCode = lastWrangler.getCode()

  regex = new RegExp("(#{breedName}-own\\s+\\[.*?)( *)\\]", "ms")
  newCode =
    if regex.test(oldCode)
      # Regex paths commented by Jason B. (5/21/21)
      # Path 1: There is already a `breed-owns` declaration for this breed, so append to it
      oldCode.replace(regex, "$1 #{varName}$2]")
    else
      regex2 = new RegExp("(.*?)^((?:^ *;.*?)*(?:to |to-report ).*)", "ms")
      if regex2.test(oldCode)
        # Path 2: There's no declaration for this breed, so make a new one.
        # Place it just before the declaration (and any comments) for the first procedure.
        oldCode.replace(regex2, "$1#{breedName}-own [ #{varName} ]\n\n$2")
      else
        # Path 3: There are no procedures; simply append the new declaration to the code
        "#{oldCode}\n\n#{breedName}-own [ #{varName} ]"
  lastWrangler = lastWrangler.withCode(newCode)

  return

recompile = ->
  genConfigP().then((config) -> reinitialize(lastWrangler, config))
  return

window.addEventListener('message', (e) ->
  switch e.data.type
    when "hnw-author-bundle"
      { hnwNlogo, ...bundle } = e.data.bundle
      initialize(hnwNlogo, bundle)
    when "hnw-author-pair"
      initialize(e.data.nlogo, e.data.config)
    when "new-breed-var"
      addNewBreedVar(e.data.breed, e.data.var)
      recompile()
    when "delete-me"
      iframe        = e.source.frameElement
      roleName      = iframe.dataset.roleName
      button        = document.querySelector(".role.hnw-button.config-tab[value='#{roleName}']")
      codeTabButton = document.getElementById('code-tab-button')
      selectConfigTab(codeTabButton)
      iframe.remove()
      button.remove()
      recompile()
    when "compile-with"
      wrangler = lastWrangler.withCode(e.data.code)
      genConfigP().then((config) -> reinitialize(wrangler, config))
    when "recompile"
      recompile()
    when "resize-me"
      { height, width, hnwID } = e.data.data
      f = (c) -> c.contentWindow is e.source or c.contentWindow.hnwID is hnwID
      containers = Array.from(document.querySelectorAll("iframe.model-container"))
      container  = containers.find(f)
      container.height = height
      container.width  = width
    when "code-save-response", "role-save-response"
    else
      console.warn("Unknown event type", e.data)
)

recombine = (sections) ->
  sections.join(sep) + "\n"

startInterval = ->
  setInterval((
    ->
      remaining = []
      while queue.length > 0
        entry                        = queue.shift()
        { frame, message, callback } = entry
        if frame.contentWindow.onmessage?
          frame.contentWindow.postMessage(message, "*")
          callback()
        else
          remaining.push(entry)
      queue = remaining
  ), 50)
  return

cancelInterval = ->
  if intervalID?
    clearInterval(intervalID)
  queue      = []
  intervalID = undefined
  return

cancelInterval()

import newModel          from "/new-model.js"
import generateHNWConfig from './hnw-config-file-generator.js'

lastNlogoSections = null # Array[String]
promiseID         = 0    # Number

# type Entry = { frame :: IFrame, message :: Object[Any], callback :: () => Unit }
queue      = undefined # Array[Entry]
intervalID = undefined # Number

sep = '\n@#$#@#$#@'

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
  document.getElementById("mode-controls"    ).classList.remove("hidden")
  document.getElementById("start-over-button").classList.add(   "hidden")
  document.getElementById("config-content"   ).classList.add(    "invis")
  cancelInterval()

# () => Unit
document.getElementById("from-scratch-button").onclick = ->

  modelText = """breed [ students student ]

to setup
end

to go
end#{newModel}"""

  config = generateHNWConfig(modelText)
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
        config = generateHNWConfig(modelText)
        initialize(modelText, config)
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
        config        = JSON.parse(configText)
        initialize(baseModelText, config)
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

        bundle = JSON.parse(bundleText)

        if bundle.hnwNlogo?
          nlogo = bundle.hnwNlogo
          delete bundle.hnwNlogo
          initialize(nlogo, bundle)

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
initialize = (nlogo, config) ->

  modelSections = nlogo.split(sep)

  if modelSections.length is 12

    lastNlogoSections = modelSections

    document.getElementById("mode-controls"    ).classList.add(   "hidden")
    document.getElementById("start-over-button").classList.remove("hidden")
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

    reinitialize(nlogo, config)

  else
    alert(new Error("Invalid '.nlogo' file; must have 12 sections"))

  return

# (String, String) => Unit
reinitialize = (nlogo, config) ->

  document.getElementById("download-nlogo-button" ).disabled = false
  document.getElementById("download-bundle-button").disabled = false

  modelSections = nlogo.split(sep)

  if modelSections.length is 12

    lastNlogoSections = modelSections

    codeFrame = document.getElementById('code-frame')

    postWhenReady(codeFrame, {
      code: modelSections[0]
    , type: "import-code"
    })

    compiler = new BrowserCompiler()
    result   = compiler.fromNlogo(nlogo)

    document.getElementById('test-model-button').disabled = not result.model.success

    compiler =
      if result.model.success
        compiler
      else
        msg = result.model.result.map((x) -> x.message).join('\n')
        alert(new Error("Model did not compile:\n\n#{msg}"))
        { listGlobalVars:   (-> [])
        , listProcedures:   (-> [])
        , listVarsForBreed: (-> [ 'breed', 'color', 'heading', 'hidden?', 'label', 'label-color'
                                , 'pen-mode', 'pen-size', 'shape', 'size', 'who', 'xcor', 'ycor'])
        }

    globalVars = compiler.listGlobalVars()
    procedures = compiler.listProcedures()

    postWhenReady(codeFrame, {
      procedures
    , onGo:            config.onIterate
    , onSetup:         config.onStart
    , targetFrameRate: config.targetFrameRate
    , type:            "import-procedures"
    })

    config.roles.forEach((role) ->

      frame = document.querySelector("iframe[data-role-name=\"#{role.name}\"]")

      myVars = compiler.listVarsForBreed(role.namePlural)

      postWhenReady(frame, { globalVars
                           , myVars
                           , procedures
                           , role
                           , type: "config-with-json" })

      return

    )

  else
    alert(new Error("Invalid '.nlogo' file; must have 12 sections"))

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
        { "bottom": 472, "left": 162, "right": 591, "top": 43, "height": 429
        , "width": 429, "type": "hnwView"
        }

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

      oldCode     = lastNlogoSections[0]
      regex       = new RegExp("^\\s*breed\\s*\\[\\s*#{rolePlural}\\s+")
      breedExists = regex.test(oldCode)

      postWhenReady(myFrame, parcel, (-> if not breedExists then recompile()))

      if not breedExists

        beforeFirstProcedureRegex = new RegExp("(.*?)^((?:^ *;.*?)*(?:to |to-report ).*)", "ms")
        breedDeclaration          = "breed [ #{rolePlural} #{roleSingular} ]"

        lastNlogoSections[0] =
          if beforeFirstProcedureRegex.test(oldCode)
            oldCode.replace(beforeFirstProcedureRegex, "$1#{breedDeclaration}\n\n$2")
          else
            "#{oldCode}\n\n#{breedDeclaration}"

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

      nonSuperRoles  = roles.filter((r) -> r.name isnt "supervisor" and r.name isnt "teacher")
      studentRole    = nonSuperRoles[0]
      supervisorRole = roles.find((r) -> r.name is "supervisor" or r.name is "teacher")
      otherRoles     = nonSuperRoles.slice(1)
      roles          = [studentRole, supervisorRole].concat(otherRoles).filter((r) -> r?)

      { onIterate:       codeFrameConfig.onGo
      , onStart:         codeFrameConfig.onSetup
      , targetFrameRate: codeFrameConfig.targetFrameRate
      , roles
      , type:            "hubnet-web"
      , version:         "hnw-alpha-1"
      }

  )


# () => Promise[(String, String)]
requestNlogoAndJSON = ->

  codeFrame = document.getElementById('code-frame')

  nlogoPromise =
    postPromise(codeFrame)({ type: "request-save" }).then(
      ({ code }) ->
        nlogoSections    = lastNlogoSections.slice(0)
        nlogoSections[0] = code
        recombine(nlogoSections)
    )

  configPromise = genConfigP().then((outConfig) -> JSON.stringify(outConfig))

  Promise.all([nlogoPromise, configPromise])

# () => Unit
document.getElementById("download-bundle-button").onclick = ->

  filename = prompt("Enter file name (without file extension):", "")

  if filename?

    name = if filename.endsWith(".hnw.json" ) then filename else "#{filename}.hnw.json"

    requestNlogoAndJSON().then(
      ([nlogo, json]) ->
        obj          = JSON.parse(json)
        obj.hnwNlogo = nlogo
        download(name)(JSON.stringify(obj))
    )

  return

# () => Unit
document.getElementById("download-nlogo-button").onclick = ->

  filename = prompt("Enter file name (without file extension):", "")

  if filename?

    nlogoName = if filename.endsWith(".nlogo")       then filename else "#{filename}.nlogo"
    jsonName  = if filename.endsWith(".nlogo.json" ) then filename else "#{filename}.nlogo.json"

    requestNlogoAndJSON().then(
      ([nlogo, json]) ->
        download(nlogoName)(nlogo)
        download(jsonName)(json)
    )

  return

# () => Unit
document.getElementById("edit-model-button").onclick = ->
  configFrame    = document.getElementById("config-content-frame")
  outerTestFrame = document.getElementById("outer-test-frame")
  configFrame   .classList.remove('invis')
  outerTestFrame.classList.   add('invis')
  return

# () => Unit
document.getElementById("test-model-button").onclick = ->

  sessionName = ""

  while sessionName is ""

    sessionName = prompt("Session name?")

    if sessionName isnt "" and sessionName?

      password = prompt("Session password?")

      if password?

        requestNlogoAndJSON().then(
          ([nlogo, config]) ->

            parcel                = { type: "galapagos-direct-launch", nlogo, config, sessionName, password }
            innerTestFrame        = document.getElementById("inner-test-frame")
            innerTestFrame.onload = -> innerTestFrame.contentWindow.postMessage(parcel, "*")
            innerTestFrame.src    = "//#{window.location.hostname}:8080/host?embedded=true"

            configFrame    = document.getElementById("config-content-frame")
            outerTestFrame = document.getElementById("outer-test-frame")
            configFrame   .classList.   add('invis')
            outerTestFrame.classList.remove('invis')

        )

  return

addNewBreedVar = (breedName, varName) ->

  oldCode = lastNlogoSections[0]

  regex = new RegExp("(#{breedName}-own\\s+\\[.*?)( *)\\]", "ms")
  lastNlogoSections[0] =
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

  return

recompile = ->
  genConfigP().then((config) -> reinitialize(recombine(lastNlogoSections), config))
  return

window.addEventListener('message', (e) ->
  switch e.data.type
    when "new-breed-var"
      addNewBreedVar(e.data.breed, e.data.var)
      recompile()
    when "delete-me"
      iframe        = e.source.frameElement
      roleName      = iframe.dataset.roleName
      button        = document.querySelector(".hnw-config-tab-button[value='#{roleName}']")
      codeTabButton = document.getElementById('code-tab-button')
      selectConfigTab(codeTabButton)
      iframe.remove()
      button.remove()
      recompile()
    when "compile-with"
      nlogo = [e.data.code].concat(lastNlogoSections.slice(1)).join(sep)
      genConfigP().then((config) -> reinitialize(nlogo, config))
    when "recompile"
      recompile()
    when "code-save-response", "role-save-response"
    else
      console.warn("Unknown event type: #{e.data.type}")
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

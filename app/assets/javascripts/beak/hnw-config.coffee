lastNlogoSections = null # Array[String]
promiseID         = 0    # Number

sep = '\n@#$#@#$#@'

# (File) => Promse[String]
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

  postIt = ->
    frame.dataset.hasLoaded = true
    frame.contentWindow.postMessage(message, "*")
    callback()

  if frame.dataset.hasLoaded is "true"
    postIt()
  else
    f = frame.onload
    frame.onload =
      ->
        f?()
        postIt()

  return


# (Form) => Unit
window.submitFromScratch = (form) ->
  modelText = exports.newModel
  config = window.generateHNWConfig(modelText)
  initialize(modelText, config)
  return

# (Form) => Unit
window.submitWithoutConfigForm = (form) ->
  formData = new FormData(form)
  model    = formData.get('model-without-config')
  readFile(model).then(
    (modelText) ->
      config = window.generateHNWConfig(modelText)
      initialize(modelText, config)
  )
  return

# (Form) => Unit
window.submitConfigForm = (form) ->

  formData      = new FormData(form)
  baseModelFile = formData.get('base-model')
  configFile    = formData.get('config')

  Promise.all([baseModelFile, configFile].map(readFile)).then(
    ([baseModelText, configText]) ->
      config        = JSON.parse(configText)
      initialize(baseModelText, config)
  )

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

  tabButton = tabButtonTemplate.content.cloneNode(true)
  tabButton.querySelector('input').value = roleName
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

    document.getElementById('config-content').classList.remove("invis")

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

    reinitialize(nlogo, config)

  else
    alert(new Error("Invalid '.nlogo' file; must have 12 sections"))

  return

# (String, String) => Unit
reinitialize = (nlogo, config) ->

  document.getElementById("download-button").disabled = false

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
    , onGo:      config.onIterate
    , onSetup:   config.onStart
    , type: "import-procedures"
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
window.selectConfigTab = (elem) ->

  configFrameContainer = document.getElementById('config-frames')
  tabButtonContainer   = document.getElementById('config-tab-buttons')

  Array.from(configFrameContainer.children).forEach((child) -> child.classList.add('invis'); child.classList.remove('vis'))
  Array.from(tabButtonContainer  .children).forEach((child) -> child.classList.remove('selected'))

  index = Array.from(tabButtonContainer.children).findIndex((x) -> x is elem)
  selectedConfig = Array.from(configFrameContainer.children)[index]
  selectedConfig.classList.remove('invis')
  selectedConfig.classList.add('vis')
  elem.classList.add('selected')

  return

# () => Unit
window.addRole = (oldSingular, oldPlural) ->

  roleSingular = prompt("Role name (singular)?", oldSingular)

  sibilant     = roleSingular.endsWith("s")
  autoPlural   = "#{roleSingular}#{if sibilant then "e" else ""}s"
  rolePlural   = prompt("Role name (plural)?", oldPlural ? autoPlural)

  if roleSingular isnt "" and rolePlural isnt "" and roleSingular isnt rolePlural
    if roleSingular? and rolePlural?

      initializeRole(roleSingular)

      dummyConfig =
        { canJoinMidRun:  true
        , onCursorMove:   null
        , onCursorClick:  null
        , onDisconnect:   null
        , widgets:        [{ "bottom": 472, "left": 162, "right": 591, "top": 43, "height": 429, "width": 429, "type": "hnwView" }]
        , name:           roleSingular
        , namePlural:     rolePlural
        , onConnect:      null
        , perspectiveVar: null
        , limit:          -1
        , isSpectator:    false
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

      nonSuperRoles  = roles.filter((r) -> r.name isnt "supervisor")
      studentRole    = nonSuperRoles[0]
      supervisorRole = roles.find((r) -> r.name is "supervisor")
      otherRoles     = nonSuperRoles.slice(1)
      roles          = [studentRole, supervisorRole].concat(otherRoles).filter((r) -> r?)

      { onIterate: codeFrameConfig.onGo
      , onStart:   codeFrameConfig.onSetup
      , roles
      , type:      "hubnet-web"
      , version:   "hnw-alpha-1"
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
        nlogoSections.join(sep)
    )

  configPromise = genConfigP().then((outConfig) -> JSON.stringify(outConfig))

  Promise.all([nlogoPromise, configPromise])

# () => Unit
window.downloadNlogoAndJSON = ->

  filename = prompt("Enter file name (without file extension):", "")

  if filename?

    nlogoName = if filename.endsWith(".nlogo") then filename else "#{filename}.nlogo"
    jsonName  = if filename.endsWith(".json" ) then filename else "#{filename}.json"

    requestNlogoAndJSON().then(
      ([nlogo, json]) ->
        download(nlogoName)(nlogo)
        download(jsonName)(json)
    )

  return

# () => Unit
window.resumeEditingModel = ->
  configFrame    = document.getElementById("config-content-frame")
  outerTestFrame = document.getElementById("outer-test-frame")
  configFrame   .classList.remove('invis')
  outerTestFrame.classList.   add('invis')
  return

# () => Unit
window.testModel = ->

  sessionName = ''

  while sessionName is '' or not sessionName?
    sessionName = prompt('Session name?')

  password = prompt('Session password?')

  requestNlogoAndJSON().then(
    ([nlogo, config]) ->

      parcel                = { type: "galapagos-direct-launch", nlogo, config, sessionName, password }
      innerTestFrame        = document.getElementById("inner-test-frame")
      innerTestFrame.onload = -> innerTestFrame.contentWindow.postMessage(parcel, "*") # TODO: Specify domain; not '*'
      innerTestFrame.src    = "//#{window.location.hostname}:8080/host" # TODO: Proper/dynamic port

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
  genConfigP().then((config) -> reinitialize(lastNlogoSections.join(sep), config))
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

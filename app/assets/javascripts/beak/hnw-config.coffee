lastNlogoSections = null # Array[String]
promiseID         = 0    # Number

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

# (Window, Any) => Unit
postWhenReady = (frame, message) ->

  postIt = ->
    frame.dataset.hasLoaded = true
    frame.contentWindow.postMessage(message, "*")

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
window.submitWithoutConfigForm = (form) ->
  formData = new FormData(form)
  console.log(form)
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

# (String, String) => Unit
initialize = (nlogo, config) ->

  modelSections = nlogo.split('@#$#@#$#@')

  if modelSections.length is 12

    lastNlogoSections = modelSections

    document.getElementById('config-content').classList.remove("invis")

    configFrameContainer = document.getElementById('config-frames')
    tabButtonContainer   = document.getElementById('config-tab-buttons')
    configTemplate       = document.getElementById('config-template')
    tabButtonTemplate    = document.getElementById('tab-button-template')
    codeFrame            = document.getElementById('code-frame')
    codeTabButton        = document.getElementById('code-tab-button')

    configFrameContainer.innerHTML = ''
    configFrameContainer.appendChild(codeFrame)

    tabButtonContainer.innerHTML = ''
    tabButtonContainer.appendChild(codeTabButton)

    config.roles.forEach((role) ->

      roleConfig             = configTemplate.content.cloneNode(true)
      frame                  = roleConfig.querySelector('iframe')
      frame.dataset.roleName = role.name
      configFrameContainer.appendChild(roleConfig)

      tabButton = tabButtonTemplate.content.cloneNode(true)
      tabButton.querySelector('input').value = role.name
      tabButtonContainer.appendChild(tabButton)

      return

    )

    reinitialize(nlogo, config)

  else
    throw new Error("Invalid '.nlogo' file; must have 12 sections")

  return

# (String, String) => Unit
reinitialize = (nlogo, config) ->

  modelSections = nlogo.split('@#$#@#$#@')

  if modelSections.length is 12

    lastNlogoSections = modelSections

    codeFrame  = document.getElementById('code-frame')

    postWhenReady(codeFrame, {
      code: modelSections[0]
    , type: "import-code"
    })

    compiler = new BrowserCompiler()
    result   = compiler.fromNlogo(nlogo)

    if result.model.success

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
      msg = result.model.result.join('\n')
      throw new Error("Model did not compile:\n\n#{msg}")

  else
    throw new Error("Invalid '.nlogo' file; must have 12 sections")

  return

# (DOMElement) => Unit
window.selectConfigTab = (elem) ->

  configFrameContainer = document.getElementById('config-frames')
  tabButtonContainer   = document.getElementById('config-tab-buttons')

  Array.from(configFrameContainer.children).forEach((child) -> child.classList.add('invis'); child.classList.remove('vis'))
  Array.from(tabButtonContainer.children)  .forEach((child) -> child.classList.remove('selected'))

  index = Array.from(tabButtonContainer.children).findIndex((x) -> x is elem)
  selectedConfig = Array.from(configFrameContainer.children)[index]
  selectedConfig.classList.remove('invis')
  selectedConfig.classList.add('vis')
  elem.classList.add('selected')

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

  frames     = [codeFrame].concat(Array.from(document.querySelectorAll(".config-container")))
  promises   = frames.map((frame) -> postPromise(frame)({ type: "request-save" }))

  Promise.all(promises).then(
    ([codeFrame, roles...]) ->
      { onIterate: codeFrame.onIterate
      , onStart:   codeFrame.onStart
      , roles
      , type:      "hubnet-web"
      , version:   "hnw-alpha-1"
      }
  )


# () => Unit
window.downloadNlogoAndJSON = ->

  filename = prompt("Enter file name (without file extension):", "")

  if filename?

    nlogoName = if filename.endsWith(".nlogo") then filename else "#{filename}.nlogo"
    jsonName  = if filename.endsWith(".json" ) then filename else "#{filename}.json"

    codeFrame = document.getElementById('code-frame')

    postPromise(codeFrame)({ type: "request-save" }).then(
      ({ code }) ->
        nlogoSections    = lastNlogoSections.slice(0)
        nlogoSections[0] = code
        download(nlogoName)(nlogoSections.join('@#$#@#$#@'))
    )

    genConfigP().then((outConfig) -> download(jsonName)(JSON.stringify(outConfig)))

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

window.addEventListener('message', (e) ->
  switch e.data.type
    when "new-breed-var"
      addNewBreedVar(e.data.breed, e.data.var)
    when "recompile"
      genConfigP().then((config) -> reinitialize(lastNlogoSections.join('@#$#@#$#@'), config))
    when "code-save-response", "role-save-response"
    else
      console.warn("Unknown event type: #{e.data.type}")
)

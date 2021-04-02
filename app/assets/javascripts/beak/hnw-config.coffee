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

window.lastNlogoSections = null

# (Form) => Unit
window.submitFreshForm = (form) ->
  formData = new FormData(form)
  console.log(form)
  alert("You submitted fresh.")
  return

# (Form) => Unit
window.submitConfigForm = (form) ->

  formData      = new FormData(form)
  baseModelFile = formData.get('base-model')
  configFile    = formData.get('config')

  Promise.all([baseModelFile, configFile].map(readFile)).then(
    ([baseModelText, configText]) ->

      modelSections = baseModelText.split('@#$#@#$#@')
      config        = JSON.parse(configText)

      if modelSections.length is 12

        window.lastNlogoSections = modelSections

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

        codeFrame.onload = ->
          codeFrame.contentWindow.postMessage({
            code:  modelSections[0]
          , type:  "import-code"
          })

        onSetup = document.getElementById('on-setup-dropdown')
        onSetup.innerHTML = "<option value=\"#{config.onStart}\">#{config.onStart}</option>"

        onGo = document.getElementById('on-go-dropdown')
        onGo.innerHTML = "<option value=\"#{config.onIterate}\">#{config.onIterate}</option>"

        config.roles.forEach((role) ->

          roleConfig = configTemplate.content.cloneNode(true)
          frame      = roleConfig.querySelector('iframe')
          configFrameContainer.appendChild(roleConfig)

          frame.onload = ->
            frame.contentWindow.postMessage({ role, type: "config-with-json" })

          tabButton = tabButtonTemplate.content.cloneNode(true)
          tabButton.querySelector('input').value = role.name
          tabButtonContainer.appendChild(tabButton)

          return

        )

      else
        throw new Error("Invalid '.nlogo' file; must have 12 sections")

  )

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

# () => Unit
window.downloadNlogoAndJSON = ->

  identifier = 0

  postPromise = (target) -> (message) ->
    new Promise(
      (resolve, reject) ->
        myID     = identifier++
        listener = window.addEventListener("message", (e) ->
          if e.data.identifier is myID
            window.removeEventListener("message", listener)
            resolve(e.data.parcel)
        , false)
        target.contentWindow.postMessage(Object.assign({}, message, identifier: myID), '*')
    )

  download = (filename) -> (content) ->

    elem = document.createElement('a')
    elem.setAttribute('href', "data:text/plain;charset=utf-8,#{encodeURIComponent(content)}")
    elem.setAttribute('download', filename)

    elem.style.display = 'none'
    document.body.appendChild(elem)

    elem.click()

    document.body.removeChild(elem)

  filename = prompt("Enter file name (without file extension):", "");

  if filename?

    nlogoName = if filename.endsWith(".nlogo") then filename else "#{filename}.nlogo"
    jsonName  = if filename.endsWith(".json" ) then filename else "#{filename}.json"

    codeFrame = document.getElementById('code-frame')

    postPromise(codeFrame)({ type: "request-save" }).then(
      (m) ->
        nlogoSections    = window.lastNlogoSections.slice(0)
        nlogoSections[0] = m
        download(nlogoName)(nlogoSections.join('@#$#@#$#@'))
    )

    promises =
      Array.from(document.querySelectorAll(".config-container")).map(
        (frame) ->
          postPromise(frame)({ type: "request-save" })
      )

    Promise.all(promises).then(
      (ps) ->
        outConfig =
          { onIterate: document.getElementById('on-go-dropdown').value
          , onStart:   document.getElementById('on-setup-dropdown').value
          , roles:     ps
          , type:      "hubnet-web"
          , version:   "hnw-alpha-1"
          }
        download(jsonName)(JSON.stringify(outConfig))
    )

  return

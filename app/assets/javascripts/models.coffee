modelSelect = null

bindModelChooser = (container, onComplete, selectionChanged, currentMode) ->

  PUBLIC_PATH_SEGMENT_LENGTH = "public/".length

  adjustModelPath = (modelName) ->
    modelName.substring(PUBLIC_PATH_SEGMENT_LENGTH, modelName.length)

  modelDisplayName = (modelName) ->
    stripPrefix = (prefix, str) ->
      startsWith = (p, s) -> s.substring(0, p.length) is p
      if startsWith(prefix, str)
        str.substring(prefix.length)
      else
        str
    stripPrefix("modelslib/", adjustModelPath(modelName))

  setModelCompilationStatus = (modelName, status) ->
    if status is "not_compiling" and currentMode isnt "dev"
      $("option[value=\"#{adjustModelPath(modelName)}\"]").attr("disabled", true)
    else
      $("option[value=\"#{adjustModelPath(modelName)}\"]")
        .addClass(currentMode)
        .addClass(status)

  populateModelChoices = (select, modelNames) ->
    unselected = $('<option>').text('Select a model')
    select.append(unselected)
    for modelName in modelNames
      option = $('<option>').attr('value', adjustModelPath(modelName))
        .text(modelDisplayName(modelName))
      select.append(option)

  createModelSelection = (container, modelNames) ->
    select = $('<select>').attr('name', 'models')
      .css('width', '100%')
      .addClass('chzn-select')
    select.on('change', (e) ->
      if modelSelect.get(0).selectedIndex > 0
        modelPath   = modelSelect.get(0).value
        modelURL    = "#{modelPath}.nlogox"
        modelSplits = modelPath.split("/")
        modelName   = modelSplits[modelSplits.length - 1]
        selectionChanged(modelURL, modelName)
    )
    # This is a hack to get a message to appear at the bottom of the chosen dropdown.  It relies on knowing about the
    # `chosen-drop` div in order to add the message.  Not too bad overall, but changes to chosen can easily break this,
    # too.  -Jeremy B January 2023
    select.on('chosen:ready', (e) ->
      chosenDrop = $('.chosen-drop')
      disabledMessage = $('<a>')
        .text("Grayed out models don't yet run in NetLogo Web.")
        .attr('href', '/docs/faq#library-models')
        .click( (me) ->
          # Chosen prevents default ops on its contents somehow, so we don't let the event get that far.
          me.stopPropagation()
        )
      disabledDiv = $('<div>')
        .addClass('model-list-disabled-message')
        .append(disabledMessage)
      chosenDrop.append(disabledDiv)
    )
    populateModelChoices(select, modelNames)
    select.appendTo(container)
    select.chosen({ search_contains: true, width: "inherit"  })
    select

  $.ajax('./model/list.json', {
    complete: (req, status) ->
      allModelNames = JSON.parse(req.responseText)
      modelSelect = createModelSelection(container, allModelNames)

      if container.classList.contains('tortoise-model-list')
        $.ajax('./model/statuses.json', {
          complete: (req, status) ->
            allModelStatuses = JSON.parse(req.responseText)
            for modelName in allModelNames
              modelStatus = allModelStatuses[modelName]?.status ? 'unknown'
              setModelCompilationStatus(modelName, modelStatus)
            modelSelect.trigger('chosen:updated')
        })
      onComplete()
    }
  )

selectModel = (model) ->
  modelSelect.val(model)
  modelSelect.trigger("chosen:updated")

# (String) => Unit
selectModelByURL = (modelURL) ->

  extractNMatches =
    (regex) -> (n) -> (str) ->
      result = (new RegExp(regex)).exec(str)
      [1..n].map((matchNumber) -> result[matchNumber])

  urlIsInternal =
    (url) ->
      extractDomain = (str) -> extractNMatches(".*?//?([^/]+)|()")(1)(str)[0]
      extractDomain(window.location.href) is extractDomain(url)

  if urlIsInternal(modelURL) and modelURL.trim().endsWith("nlogox")

    regexStr            = ".*/(modelslib/|test/|demomodels/)(.+).nlogox"
    [prefix, modelName] = extractNMatches(regexStr)(2)(modelURL)
    truePrefix          = if prefix is "modelslib/" then "" else prefix

    modelPath    =     "#{prefix}#{modelName}".replace(/%20/g, " ")
    truePath     = "#{truePrefix}#{modelName}".replace(/%20/g, " ")
    choiceElems  = document.getElementsByName('models')[0].children
    choicesArray = [].slice.call(choiceElems)
    choiceElem   = choicesArray.reduce(((acc, x) -> if x.innerText is truePath then x else acc), null)

    if choiceElem?
      selectModel(modelPath)

  return

handPickedModels = [
  "Curricular Models/BEAGLE Evolution/DNA Replication Fork",
  "Curricular Models/BEAGLE Evolution/EACH/Cooperation",
  "Curricular Models/Connected Chemistry/Connected Chemistry Gas Combustion",
  "IABM Textbook/chapter 2/Simple Economy",
  "IABM Textbook/chapter 8/Sandpile Simple",
  "Sample Models/Art/Fireworks",
  "Sample Models/Art/Follower",
  "Sample Models/Biology/Ants",
  "Sample Models/Biology/BeeSmart Hive Finding",
  "Sample Models/Biology/Daisyworld",
  "Sample Models/Biology/Flocking",
  "Sample Models/Biology/Slime",
  "Sample Models/Biology/Virus",
  "Sample Models/Biology/Wolf Sheep Predation",
  "Sample Models/Chemistry & Physics/Diffusion Limited Aggregation/DLA",
  "Sample Models/Chemistry & Physics/GasLab/GasLab Gas in a Box",
  "Sample Models/Chemistry & Physics/Boiling",
  "Sample Models/Chemistry & Physics/Ising",
  "Sample Models/Chemistry & Physics/Waves/Wave Machine",
  "Sample Models/Computer Science/Cellular Automata/CA 1D Elementary",
  "Sample Models/Earth Science/Climate Change",
  "Sample Models/Earth Science/Erosion",
  "Sample Models/Earth Science/Fire",
  "Sample Models/Mathematics/3D Solids",
  "Sample Models/Mathematics/Mousetraps",
  "Sample Models/Networks/Preferential Attachment",
  "Sample Models/Networks/Team Assembly",
  "Sample Models/Networks/Virus on a Network",
  "Sample Models/Social Science/Segregation",
  "Sample Models/Social Science/Traffic Basic",
  "Sample Models/Social Science/Voting"
].map((p) -> "modelslib/#{p}")

export {
  bindModelChooser,
  selectModel,
  selectModelByURL,
  handPickedModels,
}

window.exports = window.exports ? {}

window.exports.bindModelChooser = (container, onComplete, selectionChanged, currentMode) ->

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
    select.append($('<option>').text('Select a model'))
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
        modelURL = "#{modelSelect.get(0).value}.nlogo"
        selectionChanged(modelURL)
    )
    populateModelChoices(select, modelNames)
    select.appendTo(container)
    select.chosen({search_contains: true})
    select

  $.ajax('./model/list.json', {
    complete: (req, status) ->
      allModelNames = JSON.parse(req.responseText)
      window.modelSelect = createModelSelection(container, allModelNames)

      if container.classList.contains('tortoise-model-list')
        $.ajax('./model/statuses.json', {
          complete: (req, status) ->
            allModelStatuses = JSON.parse(req.responseText)
            for modelName in allModelNames
              modelStatus = allModelStatuses[modelName]?.status ? 'unknown'
              setModelCompilationStatus(modelName, modelStatus)
            window.modelSelect.trigger('chosen:updated')
        })
      onComplete()
    }
  )

exports.selectModel = (model) ->
  modelSelect.val(model)
  modelSelect.trigger("chosen:updated")

# (String) => Unit
exports.selectModelByURL = (modelURL) ->

  extractNMatches =
    (regex) -> (n) -> (str) ->
      result = (new RegExp(regex)).exec(str)
      [1..n].map((matchNumber) -> result[matchNumber])

  urlIsInternal =
    (url) ->
      extractDomain = (str) -> extractNMatches(".*?//?([^/]+)|()")(1)(str)[0]
      extractDomain(window.location.href) is extractDomain(url)

  if urlIsInternal(modelURL)

    regexStr            = ".*/(modelslib/|test/|demomodels/)(.+).nlogo"
    [prefix, modelName] = extractNMatches(regexStr)(2)(modelURL)
    truePrefix          = if prefix is "modelslib/" then "" else prefix

    modelPath    =     "#{prefix}#{modelName}".replace(/%20/g, " ")
    truePath     = "#{truePrefix}#{modelName}".replace(/%20/g, " ")
    choiceElems  = document.getElementsByName('models')[0].children
    choicesArray = [].slice.call(choiceElems)
    choiceElem   = choicesArray.reduce(((acc, x) -> if x.innerText is truePath then x else acc), null)

    if choiceElem?
      exports.selectModel(modelPath)

  return

exports.handPickedModels = [
  "Curricular Models/BEAGLE Evolution/DNA Replication Fork",
  "Curricular Models/Connected Chemistry/Connected Chemistry Gas Combustion",
  "IABM Textbook/chapter 2/Simple Economy",
  "IABM Textbook/chapter 8/Sandpile Simple",
  "Sample Models/Art/Fireworks",
  "Sample Models/Art/Follower",
  "Sample Models/Biology/Ants",
  "Sample Models/Biology/BeeSmart Hive Finding",
  "Sample Models/Biology/Daisyworld",
  "Sample Models/Biology/Evolution/Cooperation",
  "Sample Models/Biology/Flocking",
  "Sample Models/Biology/Slime",
  "Sample Models/Biology/Virus",
  "Sample Models/Biology/Wolf Sheep Predation",
  "Sample Models/Chemistry & Physics/Diffusion Limited Aggregation/DLA",
  "Sample Models/Chemistry & Physics/GasLab/GasLab Gas in a Box",
  "Sample Models/Chemistry & Physics/Heat/Boiling",
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

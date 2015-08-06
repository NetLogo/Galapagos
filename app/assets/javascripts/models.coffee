exports.bindModelChooser = (container, onComplete, selectionChanged, currentMode) ->

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
    if status == "not_compiling" && currentMode != "dev"
      $("option[value=\"#{adjustModelPath(modelName)}\"]").remove()
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

  $.ajax('/model/list.json', {
    complete: (req, status) ->
      allModelNames = JSON.parse(req.responseText)
      window.modelSelect = createModelSelection(container, allModelNames)

      if container[0].classList.contains('tortoise-model-list')
        $.ajax('/model/statuses.json', {
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

exports.handPickedModels = [
  "Sample Models/Art/Follower",
  "Sample Models/Biology/Wolf Sheep Predation",
  "Sample Models/Biology/Ants",
  "Sample Models/Biology/Flocking",
  "Sample Models/Biology/Virus",
  "Sample Models/Biology/Daisyworld",
  "Sample Models/Biology/Evolution/Cooperation",
  "Sample Models/Computer Science/Cellular Automata/CA 1D Elementary",
  "Sample Models/Computer Science/Cellular Automata/Life Turtle-Based",
  "Sample Models/Earth Science/Fire",
  "Sample Models/Earth Science/Climate Change",
  "Sample Models/Mathematics/Mousetraps",
  "Sample Models/Mathematics/3D Solids",
  "Sample Models/Networks/Preferential Attachment",
  "Sample Models/Social Science/Voting",
  "Sample Models/Social Science/Segregation",
  "Sample Models/Social Science/Traffic Basic",
  "Sample Models/Chemistry & Physics/Diffusion Limited Aggregation/DLA",
  "Sample Models/Chemistry & Physics/Ising",
  "Sample Models/Chemistry & Physics/GasLab/GasLab Adiabatic Piston",
  "Sample Models/Chemistry & Physics/Heat/Boiling",
  "Sample Models/Chemistry & Physics/Waves/Wave Machine"
].map((p) -> "modelslib/#{p}")

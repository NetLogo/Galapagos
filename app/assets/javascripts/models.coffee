import RactiveSearchableSelect from '/beak/widgets/ractives/subcomponent/searchable-select.js'

modelApp = null

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
    adjustedPath = adjustModelPath(modelName)
    opts = modelApp.get('options')
    idx  = opts.findIndex((o) -> o.value is adjustedPath)
    return if idx < 0
    if status is "not_compiling" and currentMode isnt "dev"
      modelApp.set("options.#{idx}.disabled", true)
    else
      modelApp.set("options.#{idx}.extraClass", "#{status} #{currentMode}")

  fetch('./model/list.json')
  .then((response) -> response.json())
  .then((allModelNames) ->
    options = allModelNames.map((name) -> {
      value: adjustModelPath(name)
      label: modelDisplayName(name)
    })

    onChange = (value) ->
      modelSplits = value.split("/")
      modelName   = modelSplits[modelSplits.length - 1]
      modelURL    = "#{value}.nlogox"
      selectionChanged(modelURL, modelName)

    container.classList.add('model-list-select')

    modelApp = new RactiveSearchableSelect({
      el: container
      data: {
        options:     options
        placeholder: 'Search the Models Library'
      }
      partials: {
        footer: """
          <div class="model-list-disabled-message">
            <a href="/docs/faq#library-models">Grayed out models don't yet run in NetLogo Web.</a>
          </div>
        """
      }
      on: {
        'change': (_, value) ->
          onChange(value)
          return
      }
    })

    if container.classList.contains('tortoise-model-list')
      fetch('./model/statuses.json')
      .then((response) -> response.json())
      .then((allModelStatuses) ->
        allModelNames.forEach((modelName) ->
          modelStatus = allModelStatuses[modelName]?.status ? 'unknown'
          setModelCompilationStatus(modelName, modelStatus)
        )
      )

    onComplete()
  )
  .catch((error) ->
    console.error('Failed to load model list:', error)
  )

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
  handPickedModels,
}

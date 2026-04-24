modelWidget = null

# Pure-DOM searchable-select factory, shares CSS classes with the Ractive component.
# Returns { setValue, addOptionClass, setOptionDisabled, setFooterContent, getOptions }
createSearchableSelect = (container, options, placeholder, onChange) ->

  isOpen        = false
  filter        = ''
  highlightIdx  = -1
  selected      = null
  footerContent = null

  opts = options.map((o) -> { value: o.value, label: o.label, disabled: false, extraClasses: [] })

  filteredOpts = ->
    f = filter.toLowerCase().trim()
    if f then opts.filter((o) -> o.label.toLowerCase().includes(f)) else opts

  root = document.createElement('div')
  root.className = 'searchable-select model-list-select'

  trigger = document.createElement('button')
  trigger.type = 'button'
  trigger.className = 'ss-trigger'
  trigger.setAttribute('aria-haspopup', 'listbox')
  trigger.setAttribute('aria-expanded', 'false')

  triggerLabel = document.createElement('span')
  triggerLabel.className = 'ss-trigger-label'
  triggerLabel.textContent = placeholder

  caret = document.createElement('span')
  caret.className = 'ss-caret'
  caret.setAttribute('aria-hidden', 'true')
  caret.innerHTML = '&#9660;'

  trigger.appendChild(triggerLabel)
  trigger.appendChild(caret)
  root.appendChild(trigger)
  container.appendChild(root)

  overlayEl  = null
  dropdownEl = null
  searchEl   = null
  listEl     = null

  renderList = ->
    if listEl?
      listEl.innerHTML = ''
      visible = filteredOpts()
      visible.forEach((opt, i) ->
        li = document.createElement('li')
        li.className = 'ss-option'
        li.setAttribute('role', 'option')
        li.setAttribute('aria-selected', String(opt.value is selected))
        if opt.disabled then li.classList.add('ss-disabled')
        opt.extraClasses.forEach((c) -> li.classList.add(c))
        if i is highlightIdx then li.classList.add('ss-highlighted')
        li.textContent = opt.label
        li.addEventListener('click', (e) ->
          e.stopPropagation()
          if not opt.disabled
            pickOption(opt.value)
        )
        listEl.appendChild(li)
      )
    return

  openDropdown = ->
    isOpen       = true
    filter       = ''
    highlightIdx = -1
    trigger.setAttribute('aria-expanded', 'true')

    overlayEl = document.createElement('div')
    overlayEl.className = 'ss-overlay'
    overlayEl.addEventListener('click', closeDropdown)
    document.body.appendChild(overlayEl)

    dropdownEl = document.createElement('div')
    dropdownEl.className = 'ss-dropdown'

    searchEl = document.createElement('input')
    searchEl.className = 'ss-search'
    searchEl.type = 'text'
    searchEl.placeholder = 'Search...'
    searchEl.autocomplete = 'off'
    searchEl.spellcheck = false
    searchEl.addEventListener('input', (e) ->
      filter = e.target.value
      highlightIdx = -1
      renderList()
    )
    searchEl.addEventListener('keydown', onSearchKeydown)

    listEl = document.createElement('ul')
    listEl.className = 'ss-list'
    listEl.setAttribute('role', 'listbox')

    dropdownEl.appendChild(searchEl)
    dropdownEl.appendChild(listEl)
    if footerContent?
      dropdownEl.appendChild(footerContent)

    root.appendChild(dropdownEl)
    renderList()
    setTimeout((-> searchEl.focus()), 0)

  closeDropdown = ->
    isOpen = false
    trigger.setAttribute('aria-expanded', 'false')
    if overlayEl?
      overlayEl.removeEventListener('click', closeDropdown)
      overlayEl.remove()
      overlayEl = null
    if dropdownEl?
      dropdownEl.remove()
      dropdownEl = null
    searchEl = null
    listEl   = null
    setTimeout((-> trigger.focus()), 0)

  scrollIntoView = (idx) ->
    if listEl?
      listEl.querySelectorAll('.ss-option')[idx]?.scrollIntoView({ block: 'nearest' })
    return

  pickOption = (value) ->
    opt = opts.find((o) -> o.value is value)
    if opt? and not opt.disabled
      selected = value
      triggerLabel.textContent = opt.label
      nativeSel.value = value
      closeDropdown()
      onChange(value)
    return

  onSearchKeydown = (e) ->
    visible = filteredOpts()
    switch e.key
      when 'ArrowDown'
        e.preventDefault()
        highlightIdx = Math.min(highlightIdx + 1, visible.length - 1)
        renderList()
        scrollIntoView(highlightIdx)
      when 'ArrowUp'
        e.preventDefault()
        highlightIdx = Math.max(highlightIdx - 1, -1)
        renderList()
        if highlightIdx >= 0 then scrollIntoView(highlightIdx)
      when 'Enter'
        e.preventDefault()
        opt = visible[highlightIdx]
        if opt? and not opt.disabled then pickOption(opt.value)
      when 'Escape'
        e.stopPropagation()
        closeDropdown()
      when 'Tab'
        closeDropdown()

  nativeSel = document.createElement('select')
  nativeSel.className = 'ss-native'
  nativeSel.setAttribute('aria-hidden', 'true')
  nativeSel.setAttribute('tabindex', '-1')
  placeholderOpt = document.createElement('option')
  placeholderOpt.value = ''
  placeholderOpt.disabled = true
  placeholderOpt.selected = true
  placeholderOpt.textContent = placeholder
  nativeSel.appendChild(placeholderOpt)
  opts.forEach((opt) ->
    o = document.createElement('option')
    o.value = opt.value
    o.textContent = opt.label
    o.disabled = opt.disabled
    nativeSel.appendChild(o)
  )
  nativeSel.addEventListener('change', (e) ->
    pickOption(e.target.value)
  )
  root.appendChild(nativeSel)

  trigger.addEventListener('click', ->
    if isOpen then closeDropdown() else openDropdown()
  )
  trigger.addEventListener('keydown', (e) ->
    switch e.key
      when 'Enter', ' '
        e.preventDefault()
        if isOpen then closeDropdown() else openDropdown()
      when 'ArrowDown'
        e.preventDefault()
        if not isOpen
          openDropdown()
      when 'Escape'
        if isOpen
          e.stopPropagation()
          closeDropdown()
  )

  {
    setValue: (value) ->
      opt = opts.find((o) -> o.value is value)
      selected = if opt? then value else null
      triggerLabel.textContent = if opt? then opt.label else placeholder
      nativeSel.value = if opt? then value else ''

    addOptionClass: (value, className) ->
      opt = opts.find((o) -> o.value is value)
      if opt? then opt.extraClasses.push(className)

    setOptionDisabled: (value, disabled) ->
      opt = opts.find((o) -> o.value is value)
      if opt? then opt.disabled = disabled
      nativeOpt = nativeSel.querySelector("option[value=\"#{value}\"]")
      if nativeOpt? then nativeOpt.disabled = disabled

    setFooterContent: (el) ->
      footerContent = el
  }

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
    if status is "not_compiling" and currentMode isnt "dev"
      modelWidget.setOptionDisabled(adjustedPath, true)
    else
      modelWidget.addOptionClass(adjustedPath, currentMode)
      modelWidget.addOptionClass(adjustedPath, status)

  fetch('./model/list.json')
  .then((response) -> response.json())
  .then((allModelNames) ->
    options = allModelNames.map((name) -> {
      value: adjustModelPath(name)
      label: modelDisplayName(name)
    })

    footerEl = document.createElement('div')
    footerEl.className = 'model-list-disabled-message'
    link = document.createElement('a')
    link.textContent = "Grayed out models don't yet run in NetLogo Web."
    link.href = '/docs/faq#library-models'
    link.addEventListener('click', (e) -> e.stopPropagation())
    footerEl.appendChild(link)

    onChange = (value) ->
      modelSplits = value.split("/")
      modelName   = modelSplits[modelSplits.length - 1]
      modelURL    = "#{value}.nlogox"
      selectionChanged(modelURL, modelName)

    modelWidget = createSearchableSelect(container, options, 'Search the Models Library', onChange)
    modelWidget.setFooterContent(footerEl)

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

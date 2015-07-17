exports.bindModelChooser = (container, selectionChanged) ->

  PUBLIC_PATH_SEGMENT_LENGTH = "public/".length

  adjustModelName = (modelName) ->
    modelName.substring(PUBLIC_PATH_SEGMENT_LENGTH, modelName.length)

  setModelCompilationStatus = (modelName, status) ->
    $("option[value=\"#{adjustModelName(modelName)}\"]").addClass(status)

  populateModelChoices = (select, modelNames) ->
    select.append($('<option>').text('Select a model...'))
    for modelName in modelNames
      option = $('<option>').attr('value', adjustModelName(modelName))
        .text(adjustModelName(modelName))
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

    }
  )

exports.modelList = (container) ->
  uploadModel = (modelURL) ->
    $.ajax('assets/' + modelURL, {
        complete: (req, status) ->
          if status is 'success'
            session.open(req.responseText)
      }
    )
  exports.bindModelChooser(container, uploadModel)

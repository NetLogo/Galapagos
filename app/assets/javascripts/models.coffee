exports.bindModelChooser = (container, selectionChanged) ->
  setModelCompilationStatus = (modelName, status) ->
    $("option[value=\"#{modelName}\"]").addClass(status)

  populateModelChoices = (select, modelNames) ->
    select.append($('<option>').text('Select a model...'))
    for modelName in modelNames
      option = $('<option>').attr('value', modelName)
        .text(modelName)
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
    $.ajax("assets/modelslib/#{modelURL}", {
        complete: (req, status) ->
          if status is 'success'
            session.open(req.responseText)
      }
    )
  exports.bindModelChooser(container, uploadModel)

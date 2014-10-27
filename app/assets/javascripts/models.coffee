exports.bindModelChooser = (container, callback) ->
  $.ajax('/model/list.json', {
    complete: (req, status) ->
      window.modelSelect = $('<select>').attr('name', 'models')
                                        .css('width', '100%')
                                        .addClass('chzn-select')
      modelSelect.append($('<option>').text('Select a model...'))
      container.append(modelSelect)
      for modelName in JSON.parse(req.responseText)
        $('<option>').attr('value', modelName)
                     .text(modelName)
                     .appendTo(modelSelect)
      modelSelect.chosen({search_contains: true})
      modelSelect.on("change", (e) ->
        if modelSelect.get(0).selectedIndex > 0
          modelURL = "#{modelSelect.get(0).value}.nlogo"
          callback(modelURL)
      )
    }
  )

exports.modelList = (container) ->
  uploadModel = (modelURL) ->
    $.ajax(modelURL, {
        complete: (req, status) ->
          if status is 'success'
            session.open("/model/#{req.responseText}")
      }
    )
  exports.bindModelChooser(container, uploadModel)

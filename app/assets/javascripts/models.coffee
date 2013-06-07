exports.modelList = (container) ->
  $.ajax('/model/list.json',
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
      modelSelect.chosen(
        search_contains: true
      )
      modelSelect.on("change", (e) ->
        if modelSelect.get(0).selectedIndex > 0
          modelURL = '/model/' + modelSelect.get(0).value + '.nlogo'
          $.ajax(modelURL,
            complete: (req, status) ->
              if status == 'success'
                session.open(req.responseText)
          )
      )
  )

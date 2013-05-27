exports.modelList = (callback) ->
  $.ajax('/model/list.json',
    complete: (req, status) ->
      window.modelSelect = $('<select>').attr('name', 'models')
                                 .css('width', '100%')
      modelSelect.append($('<option>').text('Select a model...'))
      for modelName in JSON.parse(req.responseText)
        $('<option>').attr('value', modelName)
                     .text(modelName)
                     .appendTo(modelSelect)
      modelSelect.on('change', (e) ->
        if e.srcElement.selectedIndex > 0
          modelURL = '/model/' + e.srcElement.value + '.nlogo'
          $.ajax(modelURL,
            complete: (req, status) ->
              if status == 'success'
                tortoise.sessions[0].open(req.responseText)
          )
      )
      callback(modelSelect)
  )
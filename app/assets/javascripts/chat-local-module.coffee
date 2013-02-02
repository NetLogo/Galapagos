world = -1

class exports.ChatModule

  constructor: ->
    @agentList = ['observer', 'turtles', 'patches', 'links']

  evalJS: (js) ->
    eval.call(window, js)
    collectUpdates()

  runJS: (js) ->
    (new Function(js)).call(window, js)
    collectUpdates()

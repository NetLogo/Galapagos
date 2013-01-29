world = -1

class exports.ChatModule

  constructor: ->
    @agentList = ['observer', 'turtles', 'patches', 'links']

  runJS: (js) ->
    eval.call(window, js)
    collectUpdates()


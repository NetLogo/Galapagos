class exports.ChatModule

  constructor: ->
    @agentList = ['observer', 'turtles', 'patches', 'links']
    @world     = -1

  runJS: (js) ->
    preparedJS = js.replace(/world/g, "this.world") # //@ This will do bad things inside of strings!
    eval.call(window, preparedJS)
    collectUpdates()


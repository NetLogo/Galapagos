class TextHolder
  constructor: (@text) ->
    [@command, contents...] = @text.split("\n")
    @isExpanded = true

  toString: ->
    if @isExpanded
      @text
    else
      result = @command + '  ...'
      result.bold()

  change: ->
    @isExpanded = not @isExpanded

exports.TextHolder = TextHolder

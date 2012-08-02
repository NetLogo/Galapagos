class TextHolder
  constructor: (@text) ->
    [@command, contents...] = @text.split("\n")
    @isExpanded = true

  # Return Type: String
  toString: ->
    if @isExpanded
      @text
    else
      result = @command + '  ...'
      result.bold()

  # Return Type: Unit
  change: ->
    @isExpanded = not @isExpanded

exports.TextHolder = TextHolder

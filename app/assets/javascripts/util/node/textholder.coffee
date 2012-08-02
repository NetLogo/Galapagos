class TextHolder
  constructor: (@text) ->
    this.command    = @text.split("\n")[0]
    this.isExpanded = true

  toString: ->
    if (this.isExpanded)
      this.text
    else
      var result = this.command + '  ...'
      result.bold()

  change: ->
    this.isExpanded = !this.isExpanded

exports.TextHolder = TextHolder

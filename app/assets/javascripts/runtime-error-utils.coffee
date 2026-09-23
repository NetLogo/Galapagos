# (NetLogoException) => Boolean
isModelCodeError = (exception) ->
  (exception.stackTrace ? []).some( (frame) -> frame.type is 'command' or frame.type is 'reporter' )

export { isModelCodeError }

# A `run`/`runresult` frame carries no location and means the failure is still in the widget's own source; only a real
# procedure frame puts it in the model's code.  Frame types come from Tortoise's `procedure-context.coffee`.
# (NetLogoException) => Boolean
isModelCodeError = (exception) ->
  (exception.stackTrace ? []).some( (frame) -> frame.type is 'command' or frame.type is 'reporter' )

export { isModelCodeError }

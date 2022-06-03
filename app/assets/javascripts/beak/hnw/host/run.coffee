# (String, Any*) => Any
runAmbiguous = (name, args...) ->
  pp = workspace.procedurePrims
  n  = name.toLowerCase()
  if pp.hasCommand(n)
    pp.callCommand(n, args...)
    return
  else
    pp.callReporter(n, args...)

# (String, Any*) => Boolean
runCommand = (name, args...) ->
  res = workspace.procedurePrims.callCommand(name.toLowerCase(), args...)
  res is StopInterrupt

# (String, Any*) => Any
runReporter = (name, args...) ->
  workspace.procedurePrims.callReporter(name.toLowerCase(), args...)

export { runAmbiguous, runCommand, runReporter }

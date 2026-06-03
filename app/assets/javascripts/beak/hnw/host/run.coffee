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
  pp = workspace.procedurePrims
  n  = name?.toLowerCase()
  if n? and pp.hasCommand(n)
    res = pp.callCommand(n, args...)
    res is StopInterrupt
  else
    throw new Error("This HubNet button is not set up correctly: '#{name}' is not a " +
                    "0-input command procedure in this model.")

# (String, Any*) => Any
runReporter = (name, args...) ->
  workspace.procedurePrims.callReporter(name.toLowerCase(), args...)

export { runAmbiguous, runCommand, runReporter }

# (String | undefined, Array[Procedure], Boolean) => Boolean
isValidButtonProc = (procName, procedures, isSpectator) ->
  if not procName? or procName is ""
    return false
  target = procName.toLowerCase()
  procedures.some(
    (p) ->
      p.name.toLowerCase() is target and
        (not p.isReporter) and
        p.argCount is 0 and
        (p.isUseableByObserver or (p.isUseableByTurtles and not isSpectator))
  )

export default isValidButtonProc

# At the moment NetTango Web is the only consumer of this class.  Due to changes in how NetTango works since it was
# developed, some of the rewriter points are no longer used by that app.  -Jeremy B January 2023

class Rewriter

  # Called when a compile or recompile is successful.
  # () => Unit
  compileComplete: () ->
    return

  # Called to rewrite the nlogo string before initial compilation of the full nlogo model file.
  # (String) => String
  injectNlogo: (nlogo) ->
    nlogo

  # Called to rewrite the nlogo XML string before initial compilation of the full nlogo model file.
  # (String) => String
  injectNlogoXML: (nlogox) ->
    nlogox

  # Called to rewrite the code contents of a model when recompiling.
  # (String) => String
  injectCode: (code) ->
    code

  # Called to rewrite the code contents of a model when exporting as full nlogo.
  # (String) => String
  exportCode: (code) ->
    code

  # Called when recompiling to get any extra command strings to compile as well.
  # () => Array[String]
  getExtraCommands:  () ->
    []

  # Called when errors occur to re-write if necessary from injected code.  This can happen when the injected code
  # modifies the line numbers of the original code (it won't match the code editor window).  The arguments are the
  # original code, the rewritten code, and the errors.
  # (String, String, Array[String]) => Array[String]
  updateErrors: (original, rewritten, errors) ->
    errors

export default Rewriter

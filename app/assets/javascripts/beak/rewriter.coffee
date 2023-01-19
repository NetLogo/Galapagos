# So far I haven't had a reason to turn this into a real class or to add the properties as real code somewhere.  But I
# still wanted the basic shape of the Rewriter documented somewhere.  Note that due to changes in how NetTango Web
# handles recompiles on block changes, some of these are no longer used by that app.  -Jeremy B January 2023

# type Rewriter = {
#   // called to rewrite the nlogo string before initial compilation
#   injectNlogo?: (String) => String

#   // called to rewrite the code contents of a model when recompiling
#   injectCode?: (String) => String

#   // called to rewrite the code contents of a mdoel when exporting as full nlogo
#   exportCode?: (String) => String

#   // called when recompiling to get any extra command strings to compile as well
#   getExtraCommands?: () => Array[String]

#   // called when errors occur to re-write if necessary from injected code
#   // the arguments are the original code, the rewritten code, and the errors
#   updateErrors?: (String, String, Array[String]) => Array[String]

#   // called when a compile or recompile is successful
#   compileComplete?: () => Unit
# }

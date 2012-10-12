$globals = exports.$chatGlobals
globals  = exports.chatGlobals
CSS      = exports.CSS

###
Event handlers

This file used to be so full of experimental garbage!  I think I see a tumbleweed rolling through here now, though....  --JAB (10/10/12)
###
event =

  ###
  Event-handling utilities
  ###

  util: undefined

  ###
  Basic event functionality
  ###

  changeUsernameBG: (username) ->
    log      = $("#onlineLog");
    plain    = CSS.UsernamePlain
    selected = CSS.UsernameSelected
    replaceClassName = (elem, find, replacement) -> elem.className.replace(///\b#{find}\b///, replacement)
    log.children().each((_, elem) -> elem.className = replaceClassName(elem, selected, plain))
    username.className = replaceClassName(username, plain, selected)

# Final export of module
exports.event = exports.event ? event

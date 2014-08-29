class ChatTabs

  ACTIVE_CLASS:     "active_tab"
  INACTIVE_CLASS:   "inactive_tab"
  HIDDEN_TAB_CLASS: "hidden_tab_content"
  PARTNER_ATTR:     "data-partnerid"

  # (Element) => Unit
  selectTab: (elem) ->
    if not elem.classList.contains(@ACTIVE_CLASS)
      @_getAllTabs().forEach((e) => if e.classList.contains(@ACTIVE_CLASS) then @_toggleTab(e))
      @_toggleTab(elem)
    return

  # () => Array[Element]
  _getAllTabs: ->
    @_collToArray(document.getElementById("chat_tabs").children)

  # (Element) => Unit
  _toggleTab: (elem) ->
    elem.classList.toggle(@ACTIVE_CLASS)
    elem.classList.toggle(@INACTIVE_CLASS)
    partnerID  = elem.getAttribute(@PARTNER_ATTR)
    partnerDiv = document.getElementById(partnerID)
    partnerDiv.classList.toggle(@HIDDEN_TAB_CLASS)
    return

  # (HTMLCollection) => Array[Element]
  _collToArray: (coll) ->
    Array.prototype.slice.call(coll)

exports.ChatServices.Tabs = new ChatTabs

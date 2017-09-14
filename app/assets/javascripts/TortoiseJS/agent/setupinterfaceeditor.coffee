elemById = (id) ->
  document.getElementById(id)

elemsByClass = (className) ->
  document.getElementsByClassName(className)

hideElem = (elem) ->
  elem.style.display = "none"

showElem = (elem) ->
  elem.style.display = ""

arrayContains = (xs) -> (x) ->
  xs.indexOf(x) isnt -1

nodeListToArray = (nodeList) ->
  Array.prototype.slice.call(nodeList)

# [T] @ (Function1[T, T]*) => Function1[T, T]
pipeline = (functions...) ->
  (args...) ->
    [h, fs...] = functions
    out = h(args...)
    for f in fs
      out = f(out)
    out

window.attachWidgetMenus =
    ->
      menuItemDivs = pipeline(elemsByClass, nodeListToArray)('netlogo-widget-editor-menu-items')
      menuItemDivs.forEach((elem) -> hideElem(elem); elemById("netlogo-widget-context-menu").appendChild(elem))
      return

# (Ractive, (Number) => Unit) => Unit
window.setupInterfaceEditor =
  (ractive, removeWidgetById) ->

    hideContextMenu = ->
      pipeline(elemById, hideElem)("netlogo-widget-context-menu")

    document.addEventListener("click", hideContextMenu)

    document.addEventListener("contextmenu"
    , (e) ->

        latestElem = e.target
        elems      = []
        while latestElem?
          elems.push(latestElem)
          latestElem = latestElem.parentElement

        listOfLists =
          for elem in elems
            for c in elem.classList
              c

        classes  = listOfLists.reduce((acc, x) -> acc.concat(x))
        hasClass = arrayContains(classes)

        if (not hasClass("netlogo-widget")) and (not hasClass("netlogo-widget-container"))
          hideContextMenu()

    )

    window.onkeyup = (e) -> if e.keyCode is 27 then hideContextMenu()

    ractive.on('toggleInterfaceLock'
    , ->

        isEditing = not @get('isEditing')
        @set('isEditing', isEditing)

        applyClassChanges =
          if isEditing
            (e) -> e.classList.add('interface-unlocked')
          else
            (e) -> e.classList.remove('interface-unlocked')

        widgets   = pipeline(elemsByClass, nodeListToArray)("netlogo-widget")
        unlockers = pipeline(elemsByClass, nodeListToArray)("netlogo-interface-unlocker")

        widgets.concat(unlockers).forEach(applyClassChanges)

        return

    )

    handleContextMenu =
      (e, menuItemsID) ->

          if @get("isEditing")

            trueEvent = e.original
            trueEvent.preventDefault()
            trueEvent.stopPropagation()

            contextMenu               = elemById("netlogo-widget-context-menu")
            contextMenu.style.top     = "#{trueEvent.pageY}px"
            contextMenu.style.left    = "#{trueEvent.pageX}px"
            contextMenu.style.display = "block"

            for child in contextMenu.children
              hideElem(child)

            pipeline(elemById, showElem)(menuItemsID)

            false

          else
            true

    ractive.on(  'showContextMenu', handleContextMenu)
    ractive.on('*.showContextMenu', handleContextMenu)

    ractive.on('*.deleteWidget'
    , (widgetID, contextMenuID, widgetNum) ->
        deleteById = (id) ->
          elem = elemById(id)
          elem.parentElement.removeChild(elem)
        deleteById(widgetID)
        deleteById(contextMenuID)
        hideContextMenu()
        removeWidgetById(widgetNum)
        false
    )

    ractive.on('*.hideContextMenu', hideContextMenu)

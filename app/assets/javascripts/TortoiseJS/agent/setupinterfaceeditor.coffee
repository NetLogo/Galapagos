elemById = (id) ->
  document.getElementById(id)

elemsByClass = (className) ->
  document.getElementsByClassName(className)

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

# (Ractive, (Number) => Unit) => Unit
window.setupInterfaceEditor =
  (ractive) ->

    hideContextMenu = ->
      ractive.findComponent('contextMenu').fire('coverThineself')

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
      ({ component }, trueEvent) ->
        if @get("isEditing")
          trueEvent.preventDefault()
          trueEvent.stopPropagation()
          @findComponent('contextMenu').fire('revealThineself'
                                            , component.get('contextMenuOptions')
                                            , trueEvent.pageX
                                            , trueEvent.pageY
                                            )
          false
        else
          true

    ractive.on(  'showContextMenu', handleContextMenu)
    ractive.on('*.showContextMenu', handleContextMenu)
    ractive.on('*.hideContextMenu', hideContextMenu)

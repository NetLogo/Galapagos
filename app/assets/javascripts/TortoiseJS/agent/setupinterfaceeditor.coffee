arrayContains = (xs) -> (x) ->
  xs.indexOf(x) isnt -1

# (Ractive, (Number) => Unit) => Unit
window.setupInterfaceEditor =
  (ractive) ->

    justSelectIt = (event) -> ractive.findComponent('resizer').setTarget(event.component)

    selectThatWidget =
      (event, trueEvent) ->
        if ractive.get("isEditing")
          trueEvent.preventDefault()
          trueEvent.stopPropagation()
          justSelectIt(event)
        return

    deselectThoseWidgets = ->
      ractive.findComponent('resizer').clearTarget()
      return

    ractive.observe("isEditing", (isEditing) ->
      deselectThoseWidgets()
      return
    )

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
        @fire('editingModeChangedTo', isEditing)
        return
    )

    handleContextMenu =
      ({ component }, trueEvent) ->
        if @get("isEditing")
          @findComponent('contextMenu').fire('revealThineself'
                                            , component?.get('contextMenuOptions')
                                            , trueEvent.pageX
                                            , trueEvent.pageY
                                            )
          false
        else
          true

    ractive.on(  'showContextMenu', handleContextMenu)
    ractive.on('*.showContextMenu', handleContextMenu)
    ractive.on('*.hideContextMenu', hideContextMenu)
    ractive.on('*.selectComponent', justSelectIt)
    ractive.on('*.selectWidget'   , selectThatWidget)
    ractive.on('deselectWidgets'  , deselectThoseWidgets)

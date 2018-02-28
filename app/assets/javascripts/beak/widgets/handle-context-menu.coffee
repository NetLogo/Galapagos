# (Ractive) => Unit
window.handleContextMenu =
  (ractive) ->

    hideContextMenu =
      (event) ->
        if event?.button isnt 2 # Thanks, Firefox, you freaking moron. --JAB (12/6/17)
                                # See this ticket: https://bugzilla.mozilla.org/show_bug.cgi?id=184051
          contextMenu = ractive.findComponent('contextMenu')
          if contextMenu.get('visible')
            contextMenu.fire('cover-thineself')
        return

    window.addEventListener('keyup'
    , (e) ->
        if e.keyCode is 27 then hideContextMenu(e)
    )

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
        hasClass = (x) -> classes.indexOf(x) isnt -1

        if (not hasClass("netlogo-widget")) and (not hasClass("netlogo-widget-container"))
          hideContextMenu(e)

    )

    handleContextMenu =
      (a, b, c) ->

        theEditFormIsntUp = @get("isEditing") and not @findAllComponents('editForm').some((form) -> form.get('visible'))

        if theEditFormIsntUp

          [{ component }, { pageX, pageY }] =
            if not c?
              [a, b]
            else
              [b, c]

          @findComponent('contextMenu').fire('reveal-thineself', component, pageX, pageY)

          false

        else
          true

    ractive.on(  'show-context-menu', handleContextMenu)
    ractive.on('*.show-context-menu', handleContextMenu)
    ractive.on('*.hide-context-menu', hideContextMenu)

    return

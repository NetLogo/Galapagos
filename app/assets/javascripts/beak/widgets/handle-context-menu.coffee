import RactiveWidget from "./ractives/widget.js"

# (Ractive) => Unit
handleContextMenu =
  (ractive) ->

    hideContextMenu =
      (event) ->
        if event?.button isnt 2 # Thanks, Firefox, you freaking moron. --Jason B. (12/6/17)
                                # See this ticket: https://bugzilla.mozilla.org/show_bug.cgi?id=184051
          ractive.fire('unlock-selection')
          contextMenu = ractive.findComponent('contextMenu')
          if contextMenu.get('visible')
            contextMenu.unreveal()
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

    handleContextMenu = (context) ->
      component   = context.component ? this
      contextMenu = @findComponent('contextMenu')
      { pageX, pageY, clientX, clientY, isLongPress } = context.event

      # (Array[ContextMenuOption] | undefined) => Boolean
      reveal = (options) -> contextMenu.reveal(component, pageX, pageY, clientX, clientY, options)

      showWidgetOptions = =>
        @fire('lock-selection', component)
        reveal()

      isAddable = isLongPress and (not component.get('isSelected')) and (@get('selectedWidgetCount') > 0)

      menuOpened =
        if @get('isEditing') and component instanceof RactiveWidget
          if isAddable
            @fire('lock-selection')
            reveal([
              { text: "Add to Selection", isEnabled: true, action: => @fire('add-to-selection', component) }
            , { text: "Widget Options…" , isEnabled: true, action: => showWidgetOptions(); false }
            ])
          else
            showWidgetOptions()
        else
          @fire('deselect-widgets')
          reveal()

      not menuOpened # keep propagating the event if the menu didn't open

    ractive.on('*.show-context-menu', handleContextMenu)
    ractive.on('*.hide-context-menu', hideContextMenu)

    return

export default handleContextMenu

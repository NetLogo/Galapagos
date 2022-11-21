# (WidgetController) => Unit
controlEventTraffic = (controller) ->

  { ractive, viewController } = controller

  openDialogs = new Set([])

  # (Event) => Unit
  checkActionKeys = (e) ->
    nlButtonHasFocus = document.activeElement.classList.contains("netlogo-button")
    if ractive.get('hasFocus') or nlButtonHasFocus
      char = String.fromCharCode(if e.which? then e.which else e.keyCode)
      for _, w of ractive.get('widgetObj') when w.type is 'button' and
                                         w.actionKey is char and
                                         ractive.findAllComponents('buttonWidget').
                                           find((b) -> b.get('widget') is w).get('isEnabled')
        if w.forever
          w.running = not w.running
        else
          w.run()

    return

  # (String, Number, Number) => Unit
  createWidget = (widgetType, pageX, pageY) ->
    controller.createWidget(widgetType, pageX, pageY)
    return

  dropOverlay = ->
    ractive.set('isHelpVisible', false)
    ractive.set('isOverlayUp',   false)
    return

  # Thanks, Firefox.  Maybe just put the proper values in the `drag` event, in the
  # future, instead of sending us `0` for them every time? --Jason B. (11/23/17)
  # For anyone interested in seeing how a major browser can avoid fixing a simple bug
  # for over 12 years:  https://bugzilla.mozilla.org/show_bug.cgi?id=505521
  # -Jeremy B March 2021
  #
  # (RactiveEvent) => Unit
  mosaicKillerKiller = ({ event: { clientX, clientY } }) ->
    ractive.set("lastDragX", clientX)
    ractive.set("lastDragY", clientY)
    return

  onCloseDialog = (dialog) ->
    openDialogs.delete(dialog)
    ractive.set('someDialogIsOpen', openDialogs.size > 0)
    temp = document.scrollTop
    document.querySelector('.netlogo-model').focus({
      preventScroll: true
    })
    document.scrollTop = temp
    return

  onCloseEditForm = (editForm) ->
    ractive.set('someEditFormIsOpen', false)
    onCloseDialog(editForm)
    return

  onQMark = do ->

    focusedElement = undefined

    ({ target }) ->

      isProbablyEditingText =
        (target.tagName.toLowerCase() in ["input", "textarea"] and not target.readOnly) or
        target.contentEditable is "true"

      if not isProbablyEditingText

        helpIsNowVisible = not ractive.get('isHelpVisible')
        ractive.set('isHelpVisible', helpIsNowVisible)

        elem =
          if helpIsNowVisible
            focusedElement = document.activeElement
            ractive.find('#help-dialog')
          else
            focusedElement
        elem.focus()

      return

  onOpenDialog = (dialog) ->
    openDialogs.add(dialog)
    ractive.set('someDialogIsOpen', true)
    return

  onOpenEditForm = (editForm) ->
    ractive.set('someEditFormIsOpen', true)
    onOpenDialog(editForm)
    return

  # () => Unit
  onWidgetBottomChange = ->
    getBottom =
      (w) ->
        if w.type is 'plot'
          w.bottom + 3
        else
          w.bottom
    ractive.set('height', Math.max.apply(Math, getBottom(w) for own i, w of ractive.get('widgetObj') when w.bottom?))
    return

  # () => Unit
  onWidgetRightChange = ->
    getRight =
      (w) ->
        if w.type is 'plot'
          w.right + 3
        else
          w.right
    ractive.set('width' , Math.max.apply(Math, getRight(w) for own i, w of ractive.get('widgetObj') when w.right? ))
    return

  # (Any, Any, String, Number) => Unit
  onWidgetValueChange = (newVal, oldVal, keyPath, widgetNum) ->

    widgetHasValidValue =
      (widget, value) ->
        value? and
          switch widget.type
            when 'slider'   then not isNaN(value)
            when 'inputBox' then not (widget.boxedValue.type is 'Number' and isNaN(value))
            else  true

    widget = ractive.get('widgetObj')[widgetNum]

    if widget.variable? and world? and newVal isnt oldVal and widgetHasValidValue(widget, newVal)
      world.observer.setGlobal(widget.variable, newVal)

    return

  # () => Unit
  redrawView = ->
    controller.redraw()
    viewController.repaint()
    return

  # (Widget.Chooser) => Boolean
  refreshChooser = (chooser) ->
    { eq } = tortoise_require('brazier/equals')
    chooser.currentChoice = Math.max(0, chooser.choices.findIndex(eq(chooser.currentValue)))
    chooser.currentValue  = chooser.choices[chooser.currentChoice]
    world.observer.setGlobal(chooser.variable, chooser.currentValue)
    false

  # () => Unit
  refreshDims = ->
    onWidgetRightChange()
    onWidgetBottomChange()
    return

  # (String) => Unit
  rejectDupe = (varName) ->
    controller.reportError(
      'compiler',
      'update-widget-value',
      ["There is already a widget of a different type with a variable named '#{varName}'"]
    )
    return

  showWidgetErrors = (widget) ->
    if not widget.compilation.success
      controller.reportError('compiler', widget.type, widget.compilation.messages)

  # (String, String, Any) => Boolean
  renameGlobal = (oldName, newName, value) ->

    existsInObj =
      (f) -> (obj) ->
        for _, v of obj when f(v)
          return true
        false

    if not existsInObj(({ variable }) -> variable is oldName)(ractive.get('widgetObj'))
      world.observer.setGlobal(oldName, undefined)

    world.observer.setGlobal(newName, value)

    false

  # () => Unit
  resizeView = ->
    { minpxcor, maxpxcor, minpycor, maxpycor, patchsize } = viewController.model.world
    setPatchSize(patchsize)
    world.resize(minpxcor, maxpxcor, minpycor, maxpycor)
    refreshDims()
    return

  # (Number) => Unit
  setPatchSize = (patchSize) ->
    world.setPatchSize(patchSize)
    refreshDims()
    return

  # (String, String) => Unit
  toggleBoolean = (dataName, notifyEvent) ->
    if not ractive.get('someDialogIsOpen')
      newData = not ractive.get(dataName)
      ractive.set(dataName, newData)
      if notifyEvent?
        ractive.fire(notifyEvent, newData)
    return

  # (Node) => Unit
  trackFocus = (node) ->
    ractive.set('hasFocus', document.activeElement is node)
    return

  # (_, Number, Boolean, Array[Any]) => Unit
  unregisterWidget = (_, id, wasNew, extraNotificationArgs) ->
    controller.removeWidgetById(id, wasNew, extraNotificationArgs)
    refreshDims()
    return

  # () => Unit
  updateTopology = ->
    { wrappingallowedinx: wrapX, wrappingallowediny: wrapY } = viewController.model.world
    world.changeTopology(wrapX, wrapY)
    return

  mousetrap = Mousetrap(ractive.find('.netlogo-model'))
  mousetrap.bind(['up', 'down', 'left', 'right']            , (_, name) -> ractive.fire('nudge-widget', name))
  mousetrap.bind(['ctrl+shift+l', 'command+shift+l']        ,           -> ractive.fire('toggle-interface-lock'))
  mousetrap.bind(['ctrl+shift+h', 'command+shift+h']        ,           -> ractive.fire('hide-resizer'))
  mousetrap.bind('del'                                      ,           -> ractive.fire('delete-selected'))
  mousetrap.bind('escape'                                   ,           -> ractive.fire('deselect-widgets'))

  mousetrap.bind('?', onQMark)

  ractive.observe('widgetObj.*.currentValue', onWidgetValueChange)
  ractive.observe('widgetObj.*.right'       , onWidgetRightChange)
  ractive.observe('widgetObj.*.bottom'      , onWidgetBottomChange)

  ractive.on('mosaic-killer-killer' , mosaicKillerKiller)
  ractive.on('toggle-interface-lock', () -> toggleBoolean('isEditing', 'authoring-mode-toggled'))
  ractive.on('toggle-orientation'   , () -> toggleBoolean('isVertical'))
  ractive.on('*.redraw-view'        , redrawView)
  ractive.on('*.resize-view'        , resizeView)
  ractive.on('*.unregister-widget'  , unregisterWidget)
  ractive.on('*.update-topology'    , updateTopology)

  ractive.on('check-action-keys'        , (_, event)         -> checkActionKeys(event))
  ractive.on('create-widget'            , (_, type, x, y)    -> createWidget(type, x, y))
  ractive.on('drop-overlay'             , (_, event)         -> dropOverlay())
  ractive.on('*.show-widget-errors'     , (_, widget)        -> showWidgetErrors(widget))
  ractive.on('track-focus'              , (_, node)          -> trackFocus(node))
  ractive.on('*.refresh-chooser'        , (_, nada, chooser) -> refreshChooser(chooser))
  ractive.on('*.reject-duplicate-var'   , (_, varName)       -> rejectDupe(varName))
  ractive.on('*.rename-interface-global', (_, oldN, newN, x) -> renameGlobal(oldN, newN, x))
  ractive.on('*.set-patch-size'         , (_, patchSize)     -> setPatchSize(patchSize))
  ractive.on('*.update-widgets'         ,                    -> controller.updateWidgets())

  ractive.on('*.dialog-closed'   , (_, dialog) -> onCloseDialog(dialog))
  ractive.on('*.dialog-opened'   , (_, dialog) ->  onOpenDialog(dialog))
  ractive.on('*.edit-form-closed', (_, editForm) -> onCloseEditForm(editForm))
  ractive.on('*.edit-form-opened', (_, editForm) ->  onOpenEditForm(editForm))

  return

export default controlEventTraffic

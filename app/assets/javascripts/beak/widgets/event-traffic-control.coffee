# (WidgetController) => Unit
window.controlEventTraffic = (controller) ->

  { ractive, viewController } = controller

  openDialogs = new Set([])

  # (Event) => Unit
  checkActionKeys = (e) ->
    if ractive.get('hasFocus')
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
  # future, instead of sending us `0` for them every time? --JAB (11/23/17)
  #
  # (RactiveEvent) => Unit
  hailSatan = ({ event: { clientX, clientY } }) ->
    ractive.set("lastDragX", clientX)
    ractive.set("lastDragY", clientY)
    return

  onCloseDialog = (dialog) ->
    openDialogs.delete(dialog)
    ractive.set('someDialogIsOpen', openDialogs.size > 0)
    document.querySelector('.netlogo-model').focus()
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
    ractive.set('height', Math.max.apply(Math, w.bottom for own i, w of ractive.get('widgetObj') when w.bottom?))
    return

  # () => Unit
  onWidgetRightChange = ->
    ractive.set('width' , Math.max.apply(Math, w.right  for own i, w of ractive.get('widgetObj') when w.right? ))
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
    showErrors(["There is already a widget of a different type with a variable named '#{varName}'"])
    return

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

  # () => Unit
  toggleInterfaceLock = ->
    if not @get('someDialogIsOpen')
      isEditing = not ractive.get('isEditing')
      ractive.set('isEditing', isEditing)
    return

  # (Node) => Unit
  trackFocus = (node) ->
    ractive.set('hasFocus', document.activeElement is node)
    return

  # (_, Number, Boolean) => Unit
  unregisterWidget = (_, id, wasNew) ->
    controller.removeWidgetById(id, wasNew)
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

  ractive.on('hail-satan'           , hailSatan)
  ractive.on('toggle-interface-lock', toggleInterfaceLock)
  ractive.on('*.redraw-view'        , redrawView)
  ractive.on('*.resize-view'        , resizeView)
  ractive.on('*.unregister-widget'  , unregisterWidget)
  ractive.on('*.update-topology'    , updateTopology)

  ractive.on('check-action-keys'        , (_, event)         -> checkActionKeys(event))
  ractive.on('create-widget'            , (_, type, x, y)    -> createWidget(type, x, y))
  ractive.on('drop-overlay'             , (_, event)         -> dropOverlay())
  ractive.on('show-errors'              , (_, event)         -> window.showErrors(event.context.compilation.messages))
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

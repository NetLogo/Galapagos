class window.UndoRedo

  @UNDO_REDO_LIMIT: 100

  _undoStack:     []        # Array[String]
  _redoStack:     []        # Array[String]
  _currentString: undefined # POJO

  # (POJO) => Unit
  pushCurrent: (state) ->
    if (@_currentString?)
      @_undoStack.push(@_currentString)
      @resizeUndoStack()

    @_currentString = JSON.stringify(state)

    # redo stack is now invalid
    @_redoStack = []
    return

  # () => POJO
  popUndo: () ->
    if (not @canUndo())
      throw new Error("Cannot pop an empty undo stack.")

    @_redoStack.push(@_currentString)

    @_currentString = @_undoStack.pop()

    return JSON.parse(@_currentString)

  popRedo: () ->
    if (not @canRedo())
      throw new Error("Cannot pop an empty redo stack.")

    @_undoStack.push(@_currentString)

    @_currentString = @_redoStack.pop()

    return JSON.parse(@_currentString)

  # () => Unit
  reset: () ->
    @_undoStack     = []
    @_redoStack     = []
    @_currentString = null

  resizeUndoStack: () ->
    if (@_undoStack.length < UndoRedo.UNDO_REDO_LIMIT)
      return

    @_undoStack = @_undoStack.slice(1)

  canUndo: () ->
    @_undoStack.length isnt 0

  canRedo: () ->
    @_redoStack.length isnt 0

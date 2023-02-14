import { DiskSource, NewSource } from  './nlogo-source.js'

WIP_INFO_FORMAT_VERSION = 1

class WipListener
  # (NamespaceStorage, String | null)
  constructor: (@storage, storageTag) ->
    @storagePrefix = if storageTag? then "#{storageTag}:" else ""
    @nlogoSource   = null
    @session       = null
    @reverted      = null

  getWipKey: () ->
    "#{@storagePrefix}#{@nlogoSource.getWipKey()}"

  # (SessionLite) => Unit
  setSession: (session) ->
    @session = session
    # This is necessary in the case where we didn't tell the session there was WIP at initialization because we wanted
    # to avoid the "loaded from cache" popup.  It's a bit icky, I know. -Jeremy B January 2023
    if @reverted?
      @session.widgetController.ractive.set('workInProgressState', 'enabled-with-reversion')

    else
      wipKey = @getWipKey()
      @notifyOfWorkInProgress(@storage.hasKey(wipKey))

    return

  # () => String
  getCurrentNlogo: () ->
    @session.getNlogo()

  # () => String
  getModelTitle: () ->
    @session.modelTitle()

  # () => Unit
  notifyOfWorkInProgress: (hasWip) ->
    state = if hasWip then 'enabled-with-wip' else 'enabled-and-empty'
    @session.widgetController.ractive.set('workInProgressState', state)
    return

  # (NamespaceStorage, NlogoSource, String) => WipInfo | null
  getWip: () ->
    wipKey   = @getWipKey()
    maybeWip = @storage.get(wipKey)
    if maybeWip? then maybeWip else null

  # () => Unit
  revertWip: () ->
    wipKey = @getWipKey()
    @reverted = @storage.get(wipKey)
    @storage.remove(wipKey)
    return

  # () => Unit
  undoRevert: () ->
    wipKey = @getWipKey()
    @storage.set(wipKey, @reverted)
    @reverted = null
    return

  # (String, String, String) => Unit
  _storeWipInfo: (wipKey, newNlogo, title) ->
    wipInfo = {
      version:   WIP_INFO_FORMAT_VERSION
      title
      timeStamp: Date.now()
      nlogo:     newNlogo
    }
    @storage.set(wipKey, wipInfo)
    @notifyOfWorkInProgress(true)
    return

  # (String) => Unit
  _removeWipInfo: (wipKey) ->
    @storage.remove(wipKey)
    @notifyOfWorkInProgress(false)
    return

  # (String) => Unit
  _setWip: (newNlogo) ->
    @reverted = null
    wipKey    = @getWipKey()
    title     = @getModelTitle()

    if newNlogo is @nlogoSource.nlogo and "#{title}.nlogo" is @nlogoSource.fileName()
      # If the new code is just the original code, then we have no work in progress.  Unfortunately this isn't as
      # effective as I'd like, because just compiling the code can cause the nlogo contents to change due to (I
      # believe) whitespace changes.  -Jeremy B January 2023
      @_removeWipInfo(wipKey)

    else
      @nlogoSource.setModelTitle(title)
      @_storeWipInfo(wipKey, newNlogo, title)

    return

  # () => Unit
  _maybeSetWip: () ->
    try
      result = @getCurrentNlogo()
      if result.success
        @_setWip(result.result)

    catch e
      console.log("Unable to set work in progress, `getCurrentNlogo()` or `_setWip()` failed.", e)

    return

  # (String, String) => Unit
  _updateForFileExport: (fileName, newNlogo) ->
    source = new DiskSource(fileName, newNlogo)
    # If we are currently working on an imported file or a new document, the just-exported nlogo file has become our
    # authoritative source, so reset.  -Jeremy B January 2023
    if ['disk', 'new'].includes(@nlogoSource.type)
      @nlogoSource = source
      @_setWip(newNlogo)

    return

  # (CompilerErrorArgs) => Unit
  _filterCompileErrors: (compilerErrorArgs) ->
    isUserChange = ['recompile'].includes(compilerErrorArgs.source)
    if isUserChange
      @_maybeSetWip()

    return

  # These are the Listener events.
  'recompile-complete':   () -> @_maybeSetWip()
  'compiler-error':       (_, e) -> @_filterCompileErrors(e)
  'new-widget-finalized': () -> @_maybeSetWip()
  'widget-updated':       () -> @_maybeSetWip()
  'widget-deleted':       () -> @_maybeSetWip()
  'widget-moved':         () -> @_maybeSetWip()
  'info-updated':         () -> @_maybeSetWip()
  'title-changed':        () -> @_maybeSetWip()
  'nlogo-exported':       (_, { fileName, nlogo }) -> @_updateForFileExport(fileName, nlogo)

export { WipListener }

import { DiskSource, NewSource } from  './nlogo-source.js'

WIP_INFO_FORMAT_VERSION = 1

class WipListener
  # (NamespaceStorage)
  constructor: (@storage) ->
    @nlogoSource = null
    @session     = null

  # (SessionLite) => Unit
  setSession: (session) ->
    @session = session
    return

  # () => String
  getCurrentNlogo: () ->
    @session.getNlogo()

  # () => String
  getModelTitle: () ->
    @session.modelTitle()

  # () => Unit
  notifyOfWorkInProgress: (hasWip) ->
    @session.widgetController.ractive.set('hasWorkInProgress', hasWip)
    return

  # (NamespaceStorage, NlogoSource, String) => WipInfo | null
  getWip: () ->
    wipKey   = @nlogoSource.getWipKey()
    maybeWip = @storage.get(wipKey)
    if maybeWip? then maybeWip else null

  # () => unit
  revertWip: () ->
    wipKey = @nlogoSource.getWipKey()
    @storage.remove(wipKey)
    return

  # (String, String, String) => Unit
  _storeWipInfo: (wipKey, newNlogo, title) ->
    wipInfo = {
      version:   WIP_INFO_FORMAT_VERSION
      title:     title
      timeStamp: Date.now()
      nlogo:     newNlogo
    }
    @storage.set(wipKey, wipInfo)
    @notifyOfWorkInProgress(true)
    return

  _removeWipInfo: (wipKey) ->
    @storage.remove(wipKey)
    @notifyOfWorkInProgress(false)

  # (String) => Unit
  _setWip: (newNlogo) ->
    wipKey = @nlogoSource.getWipKey()
    title  = @getModelTitle()

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
    # If we are current working on an imported file or a new document, the just-exported nlogo file has become our
    # authoritative source, so reset.  -Jeremy B January 2023
    if ['disk', 'new'].includes(@nlogoSource.type)
      @nlogoSource = source
      @_setWip(newNlogo)

    return

  # These are the Listener events.
  'recompile-complete':   () -> @_maybeSetWip()
  'new-widget-finalized': () -> @_maybeSetWip()
  'widget-updated':       () -> @_maybeSetWip()
  'widget-deleted':       () -> @_maybeSetWip()
  'widget-moved':         () -> @_maybeSetWip()
  'info-updated':         () -> @_maybeSetWip()
  'title-changed':        () -> @_maybeSetWip()
  'nlogo-exported':       (_, { fileName, nlogo }) -> @_updateForFileExport(fileName, nlogo)

export { WipListener }

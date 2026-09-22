import { DiskSource, NewSource } from  './nlogo-source.js'
import { WipData } from './wip-data.js'

# type WorkInProgressState =
#   'enabled-and-empty' | 'enabled-with-unloaded-wip' | 'enabled-with-wip' | 'enabled-with-reversion'

class WipListener
  # (NamespaceStorage, String | null)
  constructor: (@storage, storageTag) ->
    @storagePrefix  = if storageTag? and storageTag.trim() isnt '' then "#{storageTag}:" else ""
    @_nlogoSource   = null
    @_data          = new WipData(@storage, @storagePrefix)
    @session        = null
    @reverted       = null
    @revertedWipKey = null
    @loadedWipKey   = null

  # () => NlogoSource | null
  getNlogoSource: () ->
    @_nlogoSource

  # (NlogoSource) => Unit
  setNlogoSource: (nlogoSource) ->
    @_data.update(nlogoSource)
    @_nlogoSource = nlogoSource
    return

  # () => String
  getWipKey: () ->
    "#{@storagePrefix}#{@getNlogoSource().getWipKey()}"

  # (SessionLite) => Unit
  setSession: (session) ->
    @session = session
    @setNlogoSource(session.nlogoSource)
    @_syncState()
    return

  # () => WorkInProgressState
  getState: () ->
    wipKey = @getWipKey()
    if @reverted? and @revertedWipKey is wipKey
      'enabled-with-reversion'
    else if not @storage.hasKey(wipKey)
      'enabled-and-empty'
    else if @loadedWipKey is wipKey
      'enabled-with-wip'
    else
      'enabled-with-unloaded-wip'

  # () => String
  getCurrentNlogo: () ->
    @session.getNlogo()

  # () => String
  getModelTitle: () ->
    @session.modelTitle()

  # () => Unit
  _syncState: () ->
    @session.widgetController.ractive.set('workInProgressState', @getState())
    return

  # () => WipInfo | null
  getWip: () ->
    wipKey   = @getWipKey()
    maybeWip = @storage.get(wipKey)
    if maybeWip? then maybeWip else null

  # Marks the stored changes as the ones the next session will run.  The caller reloads the model with the returned
  # nlogo so the source keeps the original contents for reverting.
  # () => WipInfo | null
  loadWip: () ->
    wipInfo = @getWip()
    if wipInfo?
      @loadedWipKey = @getWipKey()
      @getNlogoSource().setModelTitle(wipInfo.title)
    wipInfo

  # () => Unit
  revertWip: () ->
    wipKey          = @getWipKey()
    @reverted       = @storage.get(wipKey)
    @revertedWipKey = wipKey
    @loadedWipKey   = null
    @storage.remove(wipKey)
    # Loading and storing changes both stamp the source with the saved title, so drop it here for the original to
    # show its own title when reloaded.  --Omar Ibrahim, Sep 14 26
    @getNlogoSource().setModelTitle(null)
    return

  # () => Unit
  undoRevert: () ->
    if @reverted? and @revertedWipKey is @getWipKey()
      @storage.set(@revertedWipKey, @reverted)
      @reverted       = null
      @revertedWipKey = null

    return

  # (String, String, String) => Unit
  _storeWipInfo: (wipKey, newNlogo, title) ->
    @_data.store(wipKey, newNlogo, title)
    @loadedWipKey = wipKey
    @_syncState()
    return

  # (String) => Unit
  _removeWipInfo: (wipKey) ->
    @storage.remove(wipKey)
    @loadedWipKey = null
    @_syncState()
    return

  # (String) => Unit
  _setWip: (newNlogo) ->
    @reverted       = null
    @revertedWipKey = null
    wipKey          = @getWipKey()
    title           = @getModelTitle()

    source = @getNlogoSource()
    if newNlogo is source.nlogo and "#{title}.nlogo" is source.fileName
      # If the new code is just the original code, then we have no work in progress.  Unfortunately this isn't as
      # effective as I'd like, because just compiling the code can cause the nlogo contents to change due to (I
      # believe) whitespace changes.  -Jeremy B January 2023
      @_removeWipInfo(wipKey)

    else
      source.setModelTitle(title)
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
    if ['disk', 'new'].includes(@getNlogoSource().type)
      @setNlogoSource(source)
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

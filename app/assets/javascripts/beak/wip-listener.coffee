import { DiskSource, NewSource } from  './nlogo-source.js'

class WipListener
  # (NamespaceStorage)
  constructor: (@storage) ->
    @nlogoSource = new NewSource()
    # () => String
    @getCurrentNlogo = (() -> "")
    # () => Unit
    @notifyOfWorkInProgress = (() -> )

  # (SessionLite) => Unit
  setSession: (session) ->
    @getCurrentNlogo        = ()       -> session.getNlogo()
    @notifyOfWorkInProgress = (hasWip) -> session.widgetController.ractive.set('hasWorkInProgress', hasWip)
    return

  # (NamespaceStorage, NlogoSource, String) => String
  getWip: () ->
    wipKey   = @nlogoSource.getWipKey()
    maybeWip = @storage.get(wipKey)
    if maybeWip? then maybeWip else @nlogoSource.nlogo

  # () => unit
  revertWip: () ->
    wipKey = @nlogoSource.getWipKey()
    @storage.remove(wipKey)
    return

  # (String) => Unit
  _setWip: (newNlogo) ->
    wipKey = @nlogoSource.getWipKey()

    if newNlogo is @nlogoSource.nlogo
      # If the new code is just the original code, then we have no work in progress.  Unfortunately this isn't as
      # effective as I'd like, because just compiling the code can cause the nlogo contents to change due to (I
      # believe) whitespace changes.  -Jeremy B January 2023
      @storage.remove(wipKey)
      @notifyOfWorkInProgress(false)

    else
      maybeOldNlogo = @storage.get(wipKey)
      if (not maybeOldNlogo?) or (maybeOldNlogo isnt newNlogo)
        @storage.set(wipKey, newNlogo)
        @notifyOfWorkInProgress(true)

    return

  # () => Unit
  _maybeSetWip: () ->
    try
      result = @getCurrentNlogo()
      if result.success
        @_setWip(result.result)

    catch
      console.log("Unable to set work in progress, `getCurrentNlogo()` or `_setWip()` failed.")

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
  'nlogo-exported':       (_, { fileName, nlogo }) -> @_updateForFileExport(fileName, nlogo)

export { WipListener }

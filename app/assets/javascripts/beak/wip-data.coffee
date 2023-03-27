WIP_INFO_FORMAT_VERSION = 1

class WipData
  # (NamespaceStorage, String)
  constructor: (@storage, @storagePrefix) ->
    return

  # (NlogoSource) => Unit
  update: (nlogoSource) ->
    return

  # (String, String, String) => Unit
  store: (wipKey, newNlogo, title) ->
    wipInfo = {
      version:   WIP_INFO_FORMAT_VERSION
      title
      timeStamp: Date.now()
      nlogo:     newNlogo
    }
    @storage.set(wipKey, wipInfo)
    return

export { WipData }

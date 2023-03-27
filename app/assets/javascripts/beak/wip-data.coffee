WIP_INFO_FORMAT_VERSION = 2

class WipData
  # (NamespaceStorage, String)
  constructor: (@storage, @storagePrefix) ->
    return

  # (NlogoSource) => Unit
  update: (nlogoSource) ->
    @version1(nlogoSource)
    return

  # For version 2 we unified URLs for HTTP/HTTPS and also for same-host relative
  # (http://netlogoweb.org/my/model.nlogo -> /my/model.nlogo)
  # (https://netlogoweb.org/my/model.nlogo -> /my/model.nlogo)
  # (/my/model.nlogo -> /my/model.nlogo)
  # (https://gist.github.com/my/model.nlogo -> gist.github.com/my/model.nlogo)
  # (NlogoSource) => Unit
  version1: (nlogoSource) ->
    if nlogoSource.type isnt 'url'
      return

    # first check if the version 2 key is already stored, meaning it was already updated and skip if so.
    v2Key = "#{@storagePrefix}#{nlogoSource.getWipKey()}"
    if @storage.hasKey(v2Key)
      return

    host       = nlogoSource.host
    path       = nlogoSource.path
    isFromHost = nlogoSource.host is globalThis.location.host

    # generate all possible overlapping version 1 keys.
    possibleV1Keys = ["http://", "https://"].map( (protocol) => "#{@storagePrefix}#{protocol}#{host}#{path}" )
    if isFromHost
      possibleV1Keys.push("#{@storagePrefix}#{path}")

    # pull in any that actually exist in local storage.
    v1Keys = possibleV1Keys.filter( (k) => @storage.hasKey(k) )
    if v1Keys.length is 0
      return

    # pick the one with the most recent modified timestamp
    v1Key = if v1Keys.length is 1
      v1Keys[0]
    else
      k = v1Keys.sort( (k1, k2) => @storage.get(k1).timeStamp - @storage.get(k2).timeStamp )[0]
      console.log("Found multiple existing v1 WIP URL keys for a model, updating for v2.", v2Key, nlogoSource)
      console.log("Possible keys checked:", possibleV1Keys)
      console.log("Existing v1 keys found:", v1Keys)
      console.log("Chosen v1 key to use as v2 based on time stamps:", k)
      k

    v1Info = @storage.get(v1Key)
    @store(v2Key, v1Info.nlogo, v1Info.title)
    # If we leave these around they can cause issues when trying to revert.  But keep them backed up just in case.
    v1Keys.forEach( (k) =>
      oldInfo = @storage.get(k)
      @storage.remove(k)
      @storage.set("__v1_backup:#{k}", oldInfo)
    )

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

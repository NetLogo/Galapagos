# (Object _, [(Object _, String)], String, t) -> Object _
window.addProxyTo =
  (proxies, objKeyPairs, key, value) ->

    apply = (x) -> (f) -> f(x)

    backingValue = value

    setters =
      objKeyPairs.map(
        ([obj, key]) ->
          descriptor = Object.getOwnPropertyDescriptor(obj, key) ? {}
          descriptor.set ? ((x) -> obj[key] = x)
      )

    Object.defineProperty(proxies, key, {
      get: -> backingValue
      set: (newValue) -> backingValue = newValue; setters.forEach(apply(newValue))
    })

    proxies

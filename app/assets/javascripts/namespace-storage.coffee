# This is a simple wrapper around a Storage-esque object to provide namespace'd access for an "app" to avoid any
# collisions between them.  -Jeremy B January 2023

class NamespaceStorage

  # (String, Storage)
  constructor: (@namespace, @localStorage) ->
    inProgressJson = @localStorage.getItem(@namespace)
    if (inProgressJson)
      @inProgress = JSON.parse(inProgressJson)
      @wasFirstInstance = false
    else
      @inProgress = { }
      @localStorage.setItem(@namespace, JSON.stringify(@inProgress))
      @wasFirstInstance = true

  # (String) => Boolean
  hasKey: (key) ->
    @inProgress.hasOwnProperty(key)

  # (String) => Any
  get: (key) ->
    @inProgress[key]

  # (String, Any) => Unit
  set: (key, value) ->
    @inProgress[key] = value
    @localStorage.setItem(@namespace, JSON.stringify(@inProgress))
    return

  # (String) => Unit
  remove: (key) ->
    delete @inProgress[key]
    @localStorage.setItem(@namespace, JSON.stringify(@inProgress))
    return

# () => FakeStorage
fakeStorage = () ->
  _ls = { }
  {
    setItem:    (key, value) -> _ls[key] = value,
    getItem:    (key)        -> _ls[key],
    removeItem: (key)        -> delete _ls[key],
    clear:      ()           -> Object.getOwnPropertyNames(_ls).forEach( (key) => delete _ls[key] )
  }

export { NamespaceStorage, fakeStorage }

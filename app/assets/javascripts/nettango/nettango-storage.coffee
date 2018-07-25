class window.NetTangoStorage
  constructor: (@localStorage) ->
    inProgressJson = @localStorage.getItem('ntInProgress')
    if (inProgressJson)
      # decode the JSON
      @inProgress = JSON.parse(inProgressJson)
    else
      @inProgress = { }
      @localStorage.setItem('ntInProgress', JSON.stringify(@inProgress))

  get: (key) ->
    @inProgress[key]

  set: (key, value) ->
    @inProgress[key] = value
    @localStorage.setItem('ntInProgress', JSON.stringify(@inProgress))
    return

  @fakeStorage: () ->
    _ls = { }
    {
      setItem:    (key, value) -> _ls[key] = value,
      getItem:    (key)        -> _ls[key],
      removeItem: (key)        -> delete _ls[key],
      clear:      ()           -> Object.getOwnPropertyNames(_ls).forEach( (key) => delete _ls[key] )
    }

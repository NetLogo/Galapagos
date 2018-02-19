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

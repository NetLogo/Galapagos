class WidgetSelection

  # ((Array[Ractive]) => Unit) => WidgetSelection
  constructor: (@_onChange) ->
    @_components = []
    @_isLocked   = false

  # () => Array[Ractive]
  all: ->
    @_components.slice()

  # () => Number
  size: ->
    @_components.length

  # (Ractive) => Boolean
  has: (component) ->
    @_components.indexOf(component) isnt -1

  # (Ractive) => Unit
  set: (component) ->
    @_replaceWith([component])
    return

  # (Array[Ractive]) => Unit
  replace: (components) ->
    unique = components.filter( (c, i) -> components.indexOf(c) is i )
    isSame = (unique.length is @_components.length) and unique.every( (c, i) => c is @_components[i] )
    if not isSame
      @_replaceWith(unique)
    return

  # (Array[Ractive]) => Unit
  add: (components) ->
    newcomers = components.filter( (c) => not @has(c) )
    if newcomers.length > 0
      @_replaceWith(@_components.concat(newcomers))
    return

  # (Ractive) => Unit
  toggle: (component) ->
    if @has(component)
      @_replaceWith(@_components.filter( (c) -> c isnt component ))
    else
      @_replaceWith(@_components.concat([component]))
    return

  # () => Unit
  clear: ->
    @_replaceWith([])
    return

  # () => Unit
  lock: ->
    @_isLocked = true
    return

  # () => Unit
  unlock: ->
    @_isLocked = false
    return

  # (Array[Ractive]) => Unit
  _replaceWith: (components) ->

    if @_isLocked
      return

    for component in @_components when components.indexOf(component) is -1
      if not component.destroyed
        component.set('isSelected', false)

    for component in components when @_components.indexOf(component) is -1
      component.set('isSelected', true)

    @_components = components
    @_onChange(@all())

    return

export default WidgetSelection

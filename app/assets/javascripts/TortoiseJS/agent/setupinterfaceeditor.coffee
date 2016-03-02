elemsByClass = (className) ->
  document.getElementsByClassName(className)

nodeListToArray = (nodeList) ->
  Array.prototype.slice.call(nodeList)

# [T] @ (Function1[T, T]*) => Function1[T, T]
pipeline = (functions...) ->
  (args...) ->
    [h, fs...] = functions
    out = h(args...)
    for f in fs
      out = f(out)
    out

window.setupInterfaceEditor =
  (ractive) ->

    ractive.on('toggleInterfaceLock'
    , ->

        isEditing = not @get('isEditing')
        @set('isEditing', isEditing)

        applyClassChanges =
          if isEditing
            (e) -> e.classList.add('interface-unlocked')
          else
            (e) -> e.classList.remove('interface-unlocked')

        widgets   = pipeline(elemsByClass, nodeListToArray)("netlogo-widget")
        unlockers = pipeline(elemsByClass, nodeListToArray)("netlogo-interface-unlocker")

        widgets.concat(unlockers).forEach(applyClassChanges)

        return

    )

RactiveDragSelectionBox = Ractive.extend({
  data: -> {
    # State

    visible: false,
    # "startX", "startY", "endX", and "endY" only make sense if "visible" is true
    startX: 0,
    startY: 0,
    endX: 0,
    endY: 0
  }

  computed: {
    top: -> Math.min(@get('startY'), @get('endY'))
    left: -> Math.min(@get('startX'), @get('endX'))
    width: -> Math.abs(@get('endX') - @get('startX'))
    height: -> Math.abs(@get('endY') - @get('startY'))
  }

  # (Unit) -> boolean
  checkDragInProgress: -> @get('visible')

  # (number, number) -> Unit
  beginDrag: (x, y) ->
    @set({ visible: true, startX: x, startY: y, endX: x, endY: y })

  # Precondition: `@checkDragInProgress()` returns true.
  # (number, number) -> Unit
  continueDrag: (x, y) ->
    @set({ endX: x, endY: y })

  # (Unit) -> Unit
  endDrag: ->
    @set('visible', false)

  template: """
    {{#visible}}
      <div
        class="drag-selection-box"
        style="position:fixed; top: {{top}}px; left: {{left}}px; width: {{width}}px; height: {{height}}px;"
      ></div>
    {{/}}
  """
})


export default RactiveDragSelectionBox

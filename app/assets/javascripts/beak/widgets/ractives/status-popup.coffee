RactiveStatusPopup = Ractive.extend({

  data: -> {
    isUp:              false
    hasWorkInProgress: false
    statusTimer:       0
  }

  on: {
    'init': () ->
      if @get('hasWorkInProgress')
        @showStatus()

    'close-status': () ->
      @closeStatus()
  }

  showStatus: () ->
    @set('isUp', true)
    timer = 5
    @set('statusTimer', timer)
    timerTick = () =>
      if timer < 1
        @closeStatus()

      else
        timer = timer - 1
        @set('statusTimer', timer)
        setTimeout(timerTick, 1000)

      return

    setTimeout(timerTick, 1000)
    return

  closeStatus: () ->
    @set('isUp', false)

  # coffeelint: disable=max_line_length
  template:
    """
    {{# isUp }}
    <div class="netlogo-model-status flex-row">
      <div>
        This model has been loaded with previous work in progress found in your cache.  To reload without the changes, press <span class="netlogo-model-status-link" on-click="revert-wip">File: <strong>Revert to Original</strong></span> ({{statusTimer}}).
      </div>
      <div class="netlogo-model-status-closer" on-click="close-status">
      X
      </div>
    </div>
    {{/}}
    """
  # coffeelint: enable=max_line_length
})

export default RactiveStatusPopup

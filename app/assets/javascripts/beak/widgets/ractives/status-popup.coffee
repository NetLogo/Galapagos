CACHE_ALERT_DEFAULT_DISPLAY_TIME = 20

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

  computed: {
    'sourceMessage': () ->
      sourceType = @get('sourceType')
      switch sourceType
        when 'url'
          'model from the link'
        when 'disk'
          'model from the uploaded file'
        when 'new'
          'new blank model'
        when 'script-element'
          'model from the page'
        else
          'model'
  }

  showStatus: () ->
    @set('isUp', true)
    timer = CACHE_ALERT_DEFAULT_DISPLAY_TIME
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
        This model has been loaded with previous work in progress found in your cache.
        To reload the unmodified {{sourceMessage}},
        press <span class="netlogo-model-status-link" on-click="revert-wip">File: <strong>Revert to Original</strong></span>
        ({{statusTimer}}).
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

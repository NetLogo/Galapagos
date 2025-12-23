RactiveToast = Ractive.extend({
  # @Type RactiveToastProps
  data: () -> {
    id:        undefined  # String
    variant:   'info'     # 'info' | 'success' | 'warning' | 'error'
    message:   undefined  # String | HTMLElement
    timeout:   3000       # Number (milliseconds)
    progress:  100        # Number (percentage)
  }

  onrender: ->
    message = @get('message')
    content = if typeof message is 'string'
        message
      else if message instanceof HTMLElement
        message.outerHTML
      else
        'Message not set?'
    @resetPartial('content', content)

    timeout = @get('timeout')
    if timeout > 0
      startTime = Date.now()

      updateProgress = () =>
        elapsed = Date.now() - startTime
        remaining = Math.max(0, timeout - elapsed)
        newProgress = (remaining / timeout) * 100

        if newProgress <= 0
          @set('progress', 0)
          if @animationFrame?
            cancelAnimationFrame(@animationFrame)
            @animationFrame = null
          @fire('toast-expired', @get('id'))
        else
          @set('progress', newProgress)
          @animationFrame = requestAnimationFrame(updateProgress)

      @animationFrame = requestAnimationFrame(updateProgress)
    return

  onteardown: ->
    if @animationFrame?
      cancelAnimationFrame(@animationFrame)
    return

  partials: {
    content: "Message not registered."
  }

  template:
    """
    <div class='toast toast-{{variant}}'>
      <div class='toast-message'>
        {{> content}}
      </div>
      <div class='toast-close' on-click='@this.fire("toast-expired", @this.get("id"))'>×</div>
      <div class='toast-progress-bar'>
        <div class='toast-progress' style='width: {{progress}}%;'></div>
      </div>
    </div>
    """
})

RactiveToaster = Ractive.extend({

  data: () -> {
    toasts: {} # { [key: String]: RactiveToastProps }
  }

  components: {
    toast: RactiveToast
  },

  addToast: (toast) ->
    toasts = @get('toasts')
    toasts[toast.id] = toast
    @set('toasts', toasts)
    return

  removeToast: (toastId) ->
    toasts = @get('toasts')
    delete toasts[toastId]
    @set('toasts', toasts)
    return

  oninit: ->
    @on('*.toast-expired', (context, toastId) =>
      @removeToast(toastId)
    )
    window.NetLogoToaster = {}
    window.NetLogoToaster.addToast = (toast) =>
      @addToast(toast)
    return

  template:
    """
    <div class='toaster'>
      {{# toasts:key }}
        <toast
          id='{{key}}'
          message='{{message}}'
          timeout='{{timeout}}'
          variant='{{variant}}'
        />
      {{/}}
    </div>
    """
})

export default RactiveToaster

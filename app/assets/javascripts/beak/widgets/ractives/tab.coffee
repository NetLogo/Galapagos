

RactiveTabWidget = Ractive.extend({

  data: -> {
      name:             undefined  # String
    , title:            undefined  # String
    , show:             false      # Boolean
    , 'focus-target':   undefined  # String (Selector)
    , 'scroll-target':   undefined # String (Selector) defaults to focus-target
    , 'scroll-behavior': 'auto'    # String ('auto' | 'smooth')
    , 'scroll-block':    'nearest' # String ('start' | 'center' | 'end' | 'nearest')
    , 'scroll-inline':   'nearest' # String ('start' | 'center' | 'end' | 'nearest')
    , 'scroll-container': 'all'    # String ('all' | 'nearest')
  }

  # () => Unit
  focus: ->
    target = @find(@get('focus-target'))
    if target?
      options = @get('scroll-options') ? {}
      target.focus(options)
    return

  # () => Unit
  scrollIntoView: ->
    name = @get('name') ? 'unknown'
    target = @find(@get('focus-target'))
    if target?
      options = {
        behavior: @get('scroll-behavior')
        block:    @get('scroll-block')
        inline:   @get('scroll-inline')
        container: @get('scroll-container')
      }

      scrollTargetSelector = @get('scroll-target')
      scrollTarget = if scrollTargetSelector?
                        @find(scrollTargetSelector)
                      else
                        target
      setTimeout( ->
        scrollTarget.scrollIntoView(options)
      , 200)

  on: {
    keydown: ({ original: event}) ->
      if event.key is " " or event.key is "Enter"
        labelId = "tab-#{@get('name')}"
        @set('show', not @get('show'))
        event.preventDefault()
        event.stopPropagation()
        false
      else
        true
  }

  template:
    """
    <label id="tab-{{ name }}" class="{{>className}}" on-keydown="keydown" tabindex="0"
            aria-controls="{{ name }}-panel" aria-expanded="{{ show }}" role="tab"
            for="{{ name }}-toggle">
      <input id="{{ name }}-toggle" type="checkbox" checked="{{ show }}"
              on-change="toggle" style="display: none;" tabindex="-1"/>
      <span class="netlogo-tab-text">{{ title }}</span>
    </label>
    {{#show}}
    <div id="{{ name }}-panel" role="tabpanel" aria-labelledby="tab-{{ name }}">
      {{yield content}}
    </div>
    {{/}}
    """

  partials: {
    className: "netlogo-tab {{#show}}netlogo-active{{/}}"
  }
})

export default RactiveTabWidget

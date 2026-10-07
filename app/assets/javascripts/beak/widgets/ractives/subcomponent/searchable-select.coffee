RactiveSearchableSelect = Ractive.extend({

  data: -> {
    options:      []            # Array[{value: String, label: String, disabled?: Bool, extraClass?: String}]
    selected:     null          # String | null
    placeholder:  'Select...'  # String
    # Internal state
    isOpen:       false
    filter:       ''
    highlightIdx: -1
  }

  computed: {
    selectedLabel: ->
      sel = @get('selected')
      if sel?
        found = @get('options').find((o) -> o.value is sel)
        found?.label ? null
      else
        null

    filteredOptions: ->
      f = (@get('filter') ? '').toLowerCase().trim()
      opts = @get('options')
      if f then opts.filter((o) -> o.label.toLowerCase().includes(f)) else opts
  }

  observe: {
    filter: -> @set('highlightIdx', -1)
  }

  on: {
    'open-dropdown': (_, focusSearch = true) ->
      @set({ isOpen: true, filter: '', highlightIdx: -1 })
      @fire('open')
      if focusSearch
        setTimeout((=> @find('.ss-search')?.focus()), 0)
      return

    'close-dropdown': ->
      @set('isOpen', false)
      @fire('close')
      setTimeout((=> @find('.ss-trigger')?.focus()), 0)
      return

    'overlay-click': ->
      @set('isOpen', false)
      return

    'trigger-click': ->
      if @get('isOpen')
        @fire('close-dropdown')
      else
        @fire('open-dropdown', {}, not window.matchMedia('(pointer: coarse)').matches)
      return

    'trigger-keydown': ({ event }) ->
      switch event.key
        when 'Enter', ' '
          event.preventDefault()
          if @get('isOpen') then @fire('close-dropdown') else @fire('open-dropdown')
        when 'ArrowDown'
          event.preventDefault()
          if not @get('isOpen') then @fire('open-dropdown')
        when 'Escape'
          if @get('isOpen')
            event.stopPropagation()
            @fire('close-dropdown')
      return

    'search-keydown': ({ event }) ->
      opts = @get('filteredOptions')
      idx  = @get('highlightIdx')
      switch event.key
        when 'ArrowDown'
          event.preventDefault()
          newIdx = Math.min(idx + 1, opts.length - 1)
          @set('highlightIdx', newIdx)
          @_scrollIntoView(newIdx)
        when 'ArrowUp'
          event.preventDefault()
          newIdx = Math.max(idx - 1, -1)
          @set('highlightIdx', newIdx)
          if newIdx >= 0 then @_scrollIntoView(newIdx)
        when 'Enter'
          event.preventDefault()
          opt = opts[idx]
          if opt? and not opt.disabled
            @fire('pick-option', {}, opt.value)
        when 'Escape'
          event.stopPropagation()
          @fire('close-dropdown')
        when 'Tab'
          @set('isOpen', false)
      return

    'pick-option': (_, value) ->
      opts = @get('options')
      opt  = opts.find((o) -> o.value is value)
      return if opt?.disabled
      @set({ selected: value, isOpen: false, filter: '' })
      @fire('change', {}, value)
      return
  }

  _scrollIntoView: (idx) ->
    items = @findAll('.ss-option')
    items[idx]?.scrollIntoView({ block: 'nearest' })
    return

  # coffeelint: disable=max_line_length
  template: """
    <div class="searchable-select">
      {{#isOpen}}<div class="ss-overlay" on-click="overlay-click"></div>{{/}}
      <button type="button" class="ss-trigger" on-click="trigger-click" on-keydown="trigger-keydown"
              aria-haspopup="listbox" aria-expanded="{{isOpen}}">
        <span class="ss-trigger-label">{{selectedLabel ? selectedLabel : placeholder}}</span>
        <span class="ss-caret" aria-hidden="true">&#9660;</span>
      </button>
      {{#isOpen}}
      <div class="ss-dropdown">
        <input class="ss-search" type="text" value="{{filter}}"
               placeholder="Search..." autocomplete="off" spellcheck="false"
               on-keydown="search-keydown" />
        <ul class="ss-list" role="listbox">
          {{#each filteredOptions:i}}
          <li class="ss-option{{#extraClass}} {{extraClass}}{{/}}{{#disabled}} ss-disabled{{/}}{{# i === highlightIdx}} ss-highlighted{{/}}"
              role="option" aria-selected="{{value === selected}}"
              on-click="['pick-option', value]">{{label}}</li>
          {{/each}}
        </ul>
        {{> footer}}
      </div>
      {{/}}
    </div>
  """
  # coffeelint: enable=max_line_length

  partials: {
    footer: ''
  }

})

export default RactiveSearchableSelect

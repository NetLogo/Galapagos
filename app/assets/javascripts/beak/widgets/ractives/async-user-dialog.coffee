{ maybe, None } = tortoise_require('brazier/maybe')

window.RactiveAsyncUserDialog = Ractive.extend({

  lastUpdateMs: undefined # Number
  startX:       undefined # Number
  startY:       undefined # Number
  view:         undefined # Element

  data: -> {
    isVisible:   undefined # Boolean
  , state:       undefined # Object[Any]
  , wareaHeight: undefined # Number
  , wareaWidth:  undefined # Number
  , xLoc:        0         # Number
  , yLoc:        0         # Number
  }

  observe: {
    isVisible: (newValue, oldValue) ->
      if newValue
        @set('xLoc',  @get('wareaWidth' ) * .1       )
        @set('yLoc', (@get('wareaHeight') * .1) + 150)
        setTimeout((=> @find("#async-user-dialog").focus()), 0) # Can't focus dialog until visible --JAB (4/10/19)
        @fire('dialog-opened', this)
      else
        @fire('dialog-closed', this)
      return
  }

  on: {

    'close-popup': ->
      @set('isVisible', false)
      false

    'handle-key': ({ original: { keyCode } }) ->
      if keyCode is 13 # Enter
        buttonID =
          switch @get('state').type
            when 'chooser'    then "async-dialog-chooser-ok"
            when 'message'    then "async-dialog-message-ok"
            when 'text-input' then "async-dialog-input-ok"
            when 'yes-or-no'  then "async-dialog-yon-yes"
            else                   throw new Error("Unknown async dialog type: #{@get('state').type}")
        document.getElementById(buttonID).click()
        false
      else if keyCode is 27 # Esc
        @fire('close-popup')

    'perform-halt': ->
      @fire('close-popup')
      @get('state').callback(None)
      false

    'perform-chooser-ok': ->
      @fire('close-popup')
      elem  = document.getElementById('async-dialog-chooser')
      index = elem.selectedIndex
      elem.selectedIndex = 0
      @get('state').callback(maybe(index))
      false

    'perform-input-ok': ->
      @fire('close-popup')
      elem       = document.getElementById('async-dialog-text-input')
      value      = elem.value
      elem.value = ""
      @get('state').callback(maybe(value))
      false

    'perform-message-ok': ->
      @fire('close-popup')
      @get('state').callback(maybe(0))
      false

    'perform-no': ->
      @fire('close-popup')
      @get('state').callback(maybe(false))
      false

    'perform-yes': ->
      @fire('close-popup')
      @get('state').callback(maybe(true))
      false

    'show-state': (event, state) ->
      @set('state'    , state)
      @set('isVisible', true )
      false

    'show-chooser': (event, message, choices, callback) ->
      @fire('show-state', {}, { type: 'chooser', message, choices, callback })
      false

    'show-text-input': (event, message, callback) ->
      @fire('show-state', {}, { type: 'text-input', message, callback })
      false

    'show-yes-or-no': (event, message, callback) ->
      @fire('show-state', {}, { type: 'yes-or-no', message, callback })
      false

    'show-message': (event, message, callback) ->
      @fire('show-state', {}, { type: 'message', message, callback })
      false

    'start-drag': (event) ->

      checkIsValid = (x, y) ->
        elem = document.elementFromPoint(x, y)
        switch elem.tagName.toLowerCase()
          when "input"    then elem.type.toLowerCase() isnt "number" and elem.type.toLowerCase() isnt "text"
          when "textarea" then false
          else                 true

      CommonDrag.dragstart.call(this, event, checkIsValid, (x, y) =>
        @startX = @get('xLoc') - x
        @startY = @get('yLoc') - y
      )

    'drag-dialog': (event) ->
      CommonDrag.drag.call(this, event, (x, y) =>
        @set('xLoc', @startX + x)
        @set('yLoc', @startY + y)
      )

    'stop-drag': ->
      CommonDrag.dragend.call(this, (->))

  }

  # coffeelint: disable=max_line_length
  template:
    """
    <div id="async-user-dialog" class="async-popup"
         style="{{# !isVisible }}display: none;{{/}} top: {{yLoc}}px; left: {{xLoc}}px; max-width: {{wareaWidth * .4}}px; {{style}}"
         draggable="true" on-drag="drag-dialog" on-dragstart="start-drag" on-dragend="stop-drag"
         on-keydown="handle-key" tabindex="0">
      <div id="{{id}}-closer" class="widget-edit-closer" on-click="perform-halt">X</div>
      <div class="async-dialog-message">{{state.message}}</div>
      <div id="async-dialog-controls" class="async-dialog-controls">{{>controls}}</div>
    </div>
    """

  partials: {

    controls:
      """
      {{# state.type === 'message' }}
        <div class="async-dialog-button-row">
          <input id="async-dialog-message-ok" type="button" on-click="perform-message-ok" value="OK"/>
        </div>

      {{ elseif state.type === 'text-input' }}
        <input id="async-dialog-text-input" class="async-dialog-text-input" type="text" />
        <div class="async-dialog-button-row">
          <input id="async-dialog-input-ok" type="button" on-click="perform-input-ok" value="OK"/>
        </div>

      {{ elseif state.type === 'chooser' }}
        <div class="h-center-flexbox">
          <select id="async-dialog-chooser" class="async-dialog-chooser" style="max-width: {{wareaWidth * .3}}px">
          {{#state.choices:i}}
            <option {{# i === 0}} selected{{/}}>{{state.choices[i]}}</option>
          {{/}}
          </select>
        </div>
        <div class="async-dialog-button-row">
          <input id="async-dialog-chooser-ok" type="button" on-click="perform-chooser-ok" value="OK"/>
        </div>

      {{ elseif state.type === 'yes-or-no' }}
        <div class="async-dialog-button-row">
          <input id="async-dialog-yon-no"  type="button"                           on-click="perform-no"  value="No" />
          <input id="async-dialog-yon-yes" type="button" style="margin-left: 5px;" on-click="perform-yes" value="Yes"/>
        </div>

      {{else}}
        Invalid dialog state.

      {{/}}
      """

  }
  # coffeelint: enable=max_line_length

})

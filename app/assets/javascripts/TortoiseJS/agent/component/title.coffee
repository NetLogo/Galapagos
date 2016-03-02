window.RactiveModelTitle = Ractive.extend({
  data: {
    currentTitle: '',
    isEditable: false
  }

  oninit: ->

    defaultOnEmpty = (s) -> if s is '' then "Untitled" else s

    onEsc =
      (f) -> (e) ->
        if e.original.keyCode is 27
          f()

    @set('currentTitle', @get('modelTitle'))
    @set('inputTitle',   @get('modelTitle'))

    @on('setEditable', -> @set('isEditable', true))
    @on('changeTitle', -> @set('isEditable', false); @set('currentTitle', defaultOnEmpty(@get('inputTitle').trim())))
    @on('handleTitleEditKeyup', onEsc(=> @set('isEditable', false); @set('inputTitle', @get('currentTitle'))))

    @observe('currentTitle', (newTitle, oldTitle, k) -> @set('modelTitle', newTitle))

  # We use a form instead of a naked text input to allow completion via "Enter"
  # coffeelint: disable=max_line_length
  template:
    """
    <div class="netlogo-model-masthead">
      {{# !isEditable }}
        <div style="display: flex; justify-content: center; height: 30px; line-height: 30px;">
          <h2 class="netlogo-model-title" style="">{{ currentTitle }}</h2>
          <div alt="Edit Title" class="netlogo-title-edit-button" on-click="setEditable"></div>
        </div>
      {{else}}
        <form style="height: 30px;" onsubmit="return false;">
          <input type="text" value="{{ inputTitle }}" class="netlogo-title-input"
                 on-keyup="handleTitleEditKeyup" on-blur="changeTitle" autofocus />
          <input style="display: none" type="submit" on-click="changeTitle" />
        </form>
      {{/}}
    </div>
    """
  # coffeelint: enable=max_line_length
})

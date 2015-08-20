
window.EditableTitleWidget = Ractive.extend({
  data: {
    currentTitle: '',
    isEditable: false
  }

  oninit: ->
    @set('currentTitle', @get('modelTitle'))
    @observe('currentTitle',
      (newTitle, oldTitle, k) -> @set('modelTitle', newTitle))
    @on('setEditable',        -> @set('isEditable', true))
    @on('setNonEditable',     -> @set('isEditable', false))

  # We use a form instead of a naked text input to allow completion via "Enter"
  template:
    """
    <div class="netlogo-model-masthead">
      {{# !isEditable }}
        <h2 on-click="setEditable">{{ currentTitle }}</h2>
      {{else}}
        <form onsubmit="return false;">
          <input type="text" value="{{ currentTitle }}"
                 class="netlogo-title-input" on-blur="setNonEditable" autofocus />
          <input class="hidden" type="submit" on-click="setNonEditable" />
        </form>
      {{/}}
    </div>
    """
})

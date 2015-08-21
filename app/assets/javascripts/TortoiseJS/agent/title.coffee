
window.EditableTitleWidget = Ractive.extend({
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
          <input type="image" alt="Edit Title" class="netlogo-title-edit-button" on-click="setEditable"
                 src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAClElEQVR4Xt2b21HDMBBFN53RCVABkwqADqACSCmUQgd0ALNMxIhgad+rNf7JB3KuzrG0krFzgH0ddwDwcO4yfj5bu3+wfkHi+S8AcHOR9woAt5Y+7EXAFnzjNknYg4AZvFlCdQEceJOEygIk8GoJVQVo4FUSKgqg4FvVx3ajg10YqwngwCMcHrgkmiVUEiCBb1feLKGKAA28i4QKAih4BKXmtHokrBbAgedWd5WElQIk8GESVgnQwIdIWCGAgsd1/goArg3rPHs6ZAvgwLd1Hj/DJWQKkMD3wz1SwjFLgAY+Q8JHhgALvIeEWf57tAAPeIsEMj9SABl+3uFJ/qUnKYys/CgBrHAJedeWI6HdLY4icKn9Xm0iBETCc6fDzO0PfISADHiLhF/w3gIy4TUS/sB7ClgBL5GwCe8lYCU8MpjyrUXQFK5cBfrTzPkWAeZwowCXfK0Al3CDALd8jQC3cKUA13ypANdwhQD3fIkA93ChgJB8roCQcIGAsHyOgLBwpoDQfEpAaDhDQHj+TEB4OCEgJX8kICV8IiAtf0tAWvhAQGr+pQAq/AgAT4y5q21C5Q/v6rSBvQAq/LTxnp42d+s8Kt8dvr8dpsL/JXwTgK+c3hOXkno+bxkJlPyQK986jFPgk9n7CAlL4dsI4ArA9p4SlsNrBHhJKAGvFWCVUAaeEoCV3/JousxSN6txsyKIf+M8huK+r1/qynNWgbZJ8pBQEp6aAv0u0SKhLLxEQCt80pqA9w34O5/REbrJ4exvqBpw+R2SkUC9qbUcXjoCmgyOhDfiTe4S8FoBnOkwG31l4C0CtBJKwVsFSCWUg6cEcIoot01J+CwBZeEzBJSGjxZQHj5SwC7gowQ8dj9x5xbJZe2+AKW59eDoUQsxAAAAAElFTkSuQmCC">
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

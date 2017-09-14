window.RactiveModelTitle = Ractive.extend({
  data: -> {
    title:     undefined # String
    isEditing: undefined # Boolean
  }

  isolated: true

  oninit: ->

    defaultOnEmpty = (s) -> if s is '' then "Untitled" else s

    @on('editTitle'
    , ->
        if @get('isEditing')
          oldName = @get('title')
          newName = prompt("Enter a new name for your model", oldName)
          @set('title', defaultOnEmpty(newName) ? oldName)
        return
    )

  template:
    """
    <div class="netlogo-model-masthead">
      <div class="flex-row" style="justify-content: center; height: 30px; line-height: 30px;">
        <h2 id="netlogo-title"
            on-contextmenu="@this.fire('showContextMenu', event, 'title-context-items')"
            class="netlogo-widget netlogo-model-title"
            on-dblclick="editTitle">
          {{ title }}
        </h2>
      </div>
    </div>
    <div id="title-context-items" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item" on-click="editTitle">Edit</li>
      </ul>
    </div>
    """

})

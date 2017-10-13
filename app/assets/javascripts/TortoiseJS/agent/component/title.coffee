window.RactiveModelTitle = RactiveContextable.extend({

  data: -> {
    contextMenuOptions: [{ text: "Edit", isEnabled: true, action: => @fire('editTitle') }]
    isEditing:          undefined # Boolean
    title:              undefined # String
  }

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
            on-contextmenu="@this.fire('showContextMenu', @event)"
            class="netlogo-widget netlogo-model-title"
            on-dblclick="editTitle">
          {{ title }}
        </h2>
      </div>
    </div>
    """

})

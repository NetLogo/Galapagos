import RactiveContextable from "./contextable.js"

RactiveModelTitle = RactiveContextable.extend({

  data: -> {
    contextMenuOptions: [{ text: "Edit", isEnabled: true, action: => @fire('edit-title') }]
    isEditing:          undefined # Boolean
    title:              undefined # String
  }

  on: {

    'edit-title': ->

      defaultOnEmpty = (s) -> if s is '' then "Untitled" else s

      if @get('isEditing')
        oldName = @get('title')
        newName = prompt("Enter a new name for your model", oldName)
        @set('title', defaultOnEmpty(newName) ? oldName)

      return

  }

  template:
    """
    <div class="netlogo-model-masthead">
      <div class="flex-row netlogo-model-title-wrapper">
        <h2 id="netlogo-title"
            on-contextmenu="@this.fire('show-context-menu', @event)"
            class="netlogo-widget netlogo-model-title {{classes}}{{# isEditing }} interface-unlocked initial-color{{/}}"
            on-dblclick="edit-title">
          {{ title }}
        </h2>
      </div>
    </div>
    """

})

export default RactiveModelTitle

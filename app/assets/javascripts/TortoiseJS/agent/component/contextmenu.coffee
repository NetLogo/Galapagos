window.RactiveContextable = Ractive.extend({

  # type ContextMenuOptions = [{ text: String, isEnabled: Boolean, action: () => Unit }]

  data: -> {
    contextMenuOptions: undefined # ContextMenuOptions
  }

  standardOptions: (component) -> {
    delete: {
      text: "Delete"
    , isEnabled: true
    , action: ->
        component.fire('hideContextMenu')
        component.fire('unregisterWidget', component.get('widget').id)
    }
  , edit: { text:   "Edit", isEnabled: true, action: -> component.fire('editWidget') }
  }

})

window.RactiveContextMenu = Ractive.extend({

  data: -> {
    options: undefined # ContextMenuOptions
  }

  on: {

    coverThineself: ->
      if @el?
        contextMenu               = @find("#netlogo-widget-context-menu")
        contextMenu.style.display = "none"
      return

    revealThineself: (_, options, x, y) ->
      @set('options', options)
      contextMenu               = @find("#netlogo-widget-context-menu")
      contextMenu.style.top     = "#{y}px"
      contextMenu.style.left    = "#{x}px"
      contextMenu.style.display = "block"
      return

  }

  template:
    """
    <div id="netlogo-widget-context-menu" class="widget-context-menu">
      {{# options === undefined }}
        <div id='widget-creation-disabled-message' style="display: none;">
          Widget creation is not yet available.  Check back soon.
        </div>
      {{ else }}
        <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
          <ul class="context-menu-list">
            {{# options }}
              {{# ..isEnabled }}
                <li class="context-menu-item" on-click="..action()">{{..text}}</li>
              {{ else }}
                <li class="context-menu-item disabled">{{..text}}</li>
              {{/}}
            {{/}}
          </ul>
        </div>
      {{/}}
    </div>
    """

})

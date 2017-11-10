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
  , deleteAndRecompile: {
    text: "Delete"
  , isEnabled: true
  , action: ->
      component.fire('hideContextMenu')
      component.fire('unregisterWidget', component.get('widget').id)
      component.fire('recompile')
    }
  , edit: { text: "Edit", isEnabled: true, action: -> component.fire('editWidget') }
  }

})

window.RactiveContextMenu = Ractive.extend({

  data: -> {
    options: undefined # ContextMenuOptions
  , mouseX:          0 # Number
  , mouseY:          0 # Number
  , target:  undefined # Ractive
  , visible:     false # Boolean
  }

  on: {

    ignoreClick: ->
      false

    coverThineself: ->
      @set('visible', false)
      return

    revealThineself: (_, component, options, x, y) ->
      @set('target' , component)
      @set('visible', true)
      @set('mouseX' , x)
      @set('mouseY' , y)
      return

  }

  template:
    """
    {{# visible }}
    <div id="netlogo-widget-context-menu" class="widget-context-menu" style="top: {{mouseY}}px; left: {{mouseX}}px;">
      {{# options === undefined }}
        <div id="widget-creation-disabled-message">
          Widget creation is not yet available.  Check back soon.
        </div>
      {{ else }}
        <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
          <ul class="context-menu-list">
            {{# options }}
              {{# ..isEnabled }}
                <li class="context-menu-item" on-click="..action(target, mouseX, mouseY)">{{..text}}</li>
              {{ else }}
                <li class="context-menu-item disabled" on-click="ignoreClick">{{..text}}</li>
              {{/}}
            {{/}}
          </ul>
        </div>
      {{/}}
    </div>
    {{/}}
    """

})

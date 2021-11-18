genWidgetCreator = (ractive, name, widgetType, isEnabled = true, enabler = (-> false)) ->
  type = if ractive.get('isHNW') then "hnw" + widgetType.charAt(0).toUpperCase() + widgetType.slice(1) else widgetType
  debugger
  { text: "Create #{name}", enabler, isEnabled
  , action: (context, mouseX, mouseY) -> context.fire('create-widget', type, mouseX, mouseY)
  }

alreadyHasA = (componentName) -> (ractive) ->
  if ractive.parent?
    alreadyHasA(componentName)(ractive.parent)
  else
    not ractive.findComponent(componentName)?

defaultOptions = (ractive) ->
  [ ["Button",  "button"]
  , ["Chooser", "chooser"]
  , ["Input",   "inputBox"]
  , ["Label",   "textBox"]
  , ["Monitor", "monitor"]
  , ["Output",  "output", false, alreadyHasA('outputWidget')]
  , ["Plot",    "plot"]
  , ["Slider",  "slider"]
  , ["Switch",  "switch"]
  ].map((args) -> genWidgetCreator(ractive, args...))

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
        component.fire('hide-context-menu')
        component.fire('unregister-widget', component.get('widget').id)
    }
  , edit: { text: "Edit", isEnabled: true, action: -> component.fire('edit-widget') }
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

    'ignore-click': ->
      false

    'cover-thineself': ->
      @set('visible', false)
      @fire('unlock-selection')
      return

    'reveal-thineself': (_, component, x, y) ->

      @set('target' , component)
      @set('options', component?.get('contextMenuOptions') ? defaultOptions(@parent))
      @set('visible', @get('options').length > 0)
      @set('mouseX' , x)
      @set('mouseY' , y)

      if component instanceof RactiveWidget
        @fire('lock-selection', component)

      return

  }

  template:
    """
    {{# visible }}
    <div id="netlogo-widget-context-menu" class="widget-context-menu" style="top: {{mouseY}}px; left: {{mouseX}}px;">
      <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
        <ul class="context-menu-list">
          {{# options }}
            {{# (..enabler !== undefined && ..enabler(target)) || ..isEnabled }}
              <li class="context-menu-item" on-mouseup="..action(target, mouseX, mouseY)">{{..text}}</li>
            {{ else }}
              <li class="context-menu-item disabled" on-mouseup="ignore-click">{{..text}}</li>
            {{/}}
          {{/}}
        </ul>
      </div>
    </div>
    {{/}}
    """

})

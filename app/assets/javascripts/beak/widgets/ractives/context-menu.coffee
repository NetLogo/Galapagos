import RactiveWidget from "./widget.js"
import { focusElementVisible } from "../accessibility/utils.js"

genWidgetCreator = (ractive, name, widgetType, isEnabled = true, enabler = (-> false)) ->
  type = if ractive.get('isHNW') then "hnw" + widgetType.charAt(0).toUpperCase() + widgetType.slice(1) else widgetType
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
  , ["Note",    "textBox"]
  , ["Monitor", "monitor"]
  , ["Output",  "output", false, alreadyHasA('outputWidget')]
  , ["Plot",    "plot"]
  , ["Slider",  "slider"]
  , ["Switch",  "switch"]
  ].map((args) -> genWidgetCreator(ractive, args...))


RactiveContextMenu = Ractive.extend({

  data: -> {
    options: undefined # [ContextMenuOption]
  , mouseX:          0 # Number
  , mouseY:          0 # Number
  , target:  undefined # Ractive
  , visible:     false # Boolean
  , tabindex:        0 # Number
  }

  on: {
    'ignore-click': ->
      false

    'cover-thineself': ->
      @set('visible', false)
      @fire('unlock-selection')
      setTimeout(=>
        document.querySelector("[tabindex=\"#{ @get('tabindex') }\"]")?.focus()
      , 0)
      return

    'reveal-thineself': (_, component, x, y) ->

      @set('target' , component)
      @set('options', component?.get('contextMenuOptions') ? defaultOptions(@parent))
      @set('visible', @get('options').length > 0)
      @set('mouseX' , x)
      @set('mouseY' , y)
      @find('.context-menu-item').focus()

      tabindex = component?.get('tabIndexEnabledValue') ?
                  component?.get('tabindex')            ?
                  0
      @set('tabindex', tabindex)

      if component instanceof RactiveWidget
        @fire('lock-selection', component)

      return

    keydown: ({ original: event }) ->
      target          = event.target
      items           = Array.from(target.parentElement.children)

      if event.key is "ArrowUp" or event.key is "ArrowDown"
        event.preventDefault()
        event.stopPropagation()
        delta         = if event.key is "ArrowUp" then -1 else 1
        siblings      = items.filter((el) -> not el.classList.contains('disabled'))
        targetIndex   = Array.prototype.indexOf.call(siblings, target)
        siblingsCount = siblings.length
        newIndex      = Math.abs((targetIndex + delta)) % siblingsCount
        newTarget     = siblings[newIndex]
        focusElementVisible(newTarget)

      setTimeout(=>
        allBlurred = items.every((item) -> item isnt document.activeElement)
        if allBlurred
          @set('visible', false)
          @fire('unlock-selection')
      , 100)

      return
  }

  unreveal: ->
    @set('visible', false)
    return

  # Returns whether the context menu actually revealed itself, which will not happen if there are no options to display.
  # (Ractive, number, number) -> boolean
  reveal: (component, pageX, pageY, clientX, clientY) ->
    options = component?.getContextMenuOptions(clientX, clientY) ? []
    visible = options.length > 0
    @set({
      target: component,
      options,
      visible,
      mouseX: pageX,
      mouseY: pageY
    })

    if visible
      # while we want the context menu to be positioned relative to the page, its
      # closest positioned ancestor is out of the Ractive's control and does not
      # have a bounding box that coincides with the page, so do some math to
      # convert to absolute position (i.e. relative to nearest positioned
      # ancestor)
      offsetParent = @find('#netlogo-widget-context-menu').offsetParent
      @set({
        mouseX: pageX - offsetParent.offsetLeft,
        mouseY: pageY - offsetParent.offsetTop
      })

    visible

  template:
    """
    {{# visible }}
    <div id="netlogo-widget-context-menu"
          class="widget-context-menu" style="top: {{mouseY}}px; left: {{mouseX}}px;">
      <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
        <ul class="context-menu-list">
          {{# options }}
            {{# (..enabler !== undefined && ..enabler(target)) || ..isEnabled }}
              <li class="context-menu-item"
                  tabindex="{{tabindex}}" role="button" aria-disabled="false"
                  on-keydown="keydown"
                  on-activateClick="..action(target, mouseX, mouseY)">{{..text}}</li>
            {{ else }}
              <li class="context-menu-item disabled"
                  tabindex="-1" role="button" aria-disabled="true"
                  on-activateClick="ignore-click">{{..text}}</li>
            {{/}}
          {{/}}
        </ul>
      </div>
    </div>
    {{/}}
    """

})

export default RactiveContextMenu

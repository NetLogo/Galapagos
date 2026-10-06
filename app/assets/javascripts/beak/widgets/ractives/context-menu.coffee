import RactiveWidget from "./widget.js"
import { focusElementVisible } from "../accessibility/utils.js"

SUBMENU_PAGE_SIZE = 15

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
    options:     undefined # [ContextMenuOption]
  , mouseX:               0 # Number
  , mouseY:               0 # Number
  , target:       undefined # Ractive
  , visible:          false # Boolean
  , tabindex:             0 # Number
  , flipSubmenuX:     false # Boolean — true when submenus should open left instead of right
  , flipSubmenuY:     false # Boolean — true when submenus should open upward instead of downward
  , submenuMaxHeight: undefined # Number
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

    'open-submenu': ({ node, original: event }) ->
      if event.target.closest('.context-menu-item') is node
        node.focus()
        false

    'scroll-submenu': ({ node }, delta) ->
      list = node.parentElement.querySelector('.context-submenu-scroll')
      step = list.clientHeight - list.querySelector('.context-menu-item').offsetHeight
      list.scrollBy({ top: delta * step, behavior: 'smooth' })
      false

    'submenu-scrolled': ({ node }, optionIndex) ->
      @set("options.#{optionIndex}.hasScrollUp",   node.scrollTop > 0)
      @set("options.#{optionIndex}.hasScrollDown", node.scrollTop + node.clientHeight < node.scrollHeight - 1)
      return

    'reveal-thineself': (_, component, x, y) ->

      @set('target' , component)
      @set('options', @_processOptions(component?.get('contextMenuOptions') ? defaultOptions(@parent)))
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
        if newTarget.closest('.context-submenu-scroll')?
          newTarget.scrollIntoView({ block: 'nearest' })

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
    @get('target')?.clearSelectionCircle?()
    return

  # Returns whether the context menu actually revealed itself, which will not happen if there are no options to display.
  # (Ractive, number, number, number, number, Array[ContextMenuOption] | undefined) -> boolean
  reveal: (component, pageX, pageY, clientX, clientY, givenOptions) ->
    options = @_processOptions(givenOptions ? component?.getContextMenuOptions(clientX, clientY) ? [])
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
      menuEl        = @find('#netlogo-widget-context-menu')
      offsetParent  = menuEl.offsetParent
      menuWidth     = menuEl.offsetWidth
      menuHeight    = menuEl.offsetHeight
      itemHeight    = menuEl.querySelector('.context-menu-item').offsetHeight
      maxListHeight = Math.min(SUBMENU_PAGE_SIZE * itemHeight, window.innerHeight / 2)

      # Flip horizontal/vertical if the menu would overflow the viewport (iframe boundary)
      flippedX = clientX + menuWidth  > window.innerWidth
      flippedY = clientY + menuHeight > window.innerHeight

      # The worst-case submenu starts at the bottom of the main menu. For scrollable submenus,
      # use the list's maximum height plus the two arrows; otherwise proxy with menuHeight.
      menuBottomClientY = if flippedY then clientY else clientY + menuHeight
      submenuHeightEst  = if options.some((o) -> o.isScrollable)
        maxListHeight + 2 * itemHeight
      else
        menuHeight

      @set({
        mouseX:       pageX - offsetParent.offsetLeft - (if flippedX then menuWidth  else 0)
        mouseY:       pageY - offsetParent.offsetTop  - (if flippedY then menuHeight else 0)
        # Submenus flip left when the main menu is near the right edge
        flipSubmenuX: clientX + menuWidth + menuWidth > window.innerWidth
        # Submenus flip up when the bottom of the main menu is near the bottom edge
        flipSubmenuY: menuBottomClientY + submenuHeightEst > window.innerHeight
        submenuMaxHeight: maxListHeight
      })

    visible

  # Annotates submenu options with scroll state. Scrollable submenus (> SUBMENU_PAGE_SIZE items) get
  # scroll metadata so the template can show up/down arrow buttons around a scrolling list of items.
  # (Array[ContextMenuOption]) -> Array[ContextMenuOption]
  _processOptions: (options) ->
    options.map((opt, i) ->
      if not opt.isSubmenu
        opt
      else
        isScrollable = opt.submenu.length > SUBMENU_PAGE_SIZE
        Object.assign({}, opt, {
          optionIndex:   i,
          isScrollable,
          hasScrollUp:   false,
          hasScrollDown: isScrollable
        })
    )

  partials: {
    submenuItems:
      """
      {{# submenu }}
        <li class="context-menu-item"
            tabindex="{{tabindex}}" role="button" aria-disabled="false"
            on-keydown="keydown"
            on-activateClick="action()">{{text}}</li>
      {{/}}
      """
  }

  # coffeelint: disable=max_line_length
  template:
    """
    {{# visible }}
    <div id="netlogo-widget-context-menu"
          class="widget-context-menu" style="top: {{mouseY}}px; left: {{mouseX}}px;">
      <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
        <ul class="context-menu-list">
          {{# options }}
            {{# isSubmenu }}
              <li class="context-menu-item has-submenu"
                  tabindex="{{tabindex}}" role="button" aria-disabled="false"
                  on-keydown="keydown"
                  on-click="open-submenu">
                {{text}} &#9658;
                <ul class="context-submenu context-menu-list {{# flipSubmenuX }}flip-left{{/}} {{# flipSubmenuY }}flip-up{{/}}">
                  {{# isScrollable }}
                    <li class="context-submenu-scroll-arrow {{^ hasScrollUp }}disabled{{/}}" on-click="['scroll-submenu', -1]">&#9650;</li>
                    <li>
                      <ul class="context-submenu-scroll context-menu-list"
                          {{# submenuMaxHeight }}style="max-height: {{submenuMaxHeight}}px;"{{/}}
                          on-scroll="['submenu-scrolled', optionIndex]">
                        {{> submenuItems }}
                      </ul>
                    </li>
                    <li class="context-submenu-scroll-arrow {{^ hasScrollDown }}disabled{{/}}" on-click="['scroll-submenu', 1]">&#9660;</li>
                  {{ else }}
                    {{> submenuItems }}
                  {{/}}
                </ul>
              </li>
            {{ else }}
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
          {{/}}
        </ul>
      </div>
    </div>
    {{/}}
    """
  # coffeelint: enable=max_line_length

})

export default RactiveContextMenu

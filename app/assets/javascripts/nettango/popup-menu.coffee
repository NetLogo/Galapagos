window.RactivePopupMenu = Ractive.extend({

  # The `content` for a popup menu should be of an `Items` type - the `name` will be ignored for the `content`
  # Content = Item | Items
  # Item    = { name: String, eventName: String, data: POJO  }
  # Items   = { name: String, eventName: String, items: Array[Content] }
  # The `eventName` string is optional for an Item - if not given the event on the root `content` will be used
  # The `menuData` (if sent via the `popup()` method) and the `data` for each item will be passed to the fired event

  on: {

    'exec': (_, eventName, itemData) ->
      target   = @get('target')
      event    = eventName ? @get('content').eventName
      menuData = @get('menuData')
      if (menuData?)
        target.fire(event, {}, menuData, itemData)
      else
        target.fire(event, {}, itemData)
      return

    'popup-submenu': ({ event: { pageX, pageY } }, item) ->
      @set("submenus[#{item.level}].item", item)
      @_updatePosition(pageX, pageY, "submenus[#{item.level}].style")
      return

  }

  popup: (target, left, top, content, menuData) ->
    maxLevel = @_markContent(content)
    submenus = for num in [1..maxLevel]
      { style: "display: none;" }
    @set('submenus', submenus)
    @set('menuData', menuData)
    @set('content', content)
    @set('target', target)
    @_updatePosition(left, top, 'style')
    return

  unpop: () ->
    @set('style', 'display: none;')
    @get('submenus').forEach( (_, level) =>
      @set("submenus[#{level}].style", 'display: none;')
    )
    return

  _markContent: (content) ->
    # tag all the content levels with ID numbers
    # build a total ID array so we can create a collection of popup menu levels
    # TODO - Maybe require this be explicitly called by someone using the popup-menu
    # instead of tattoing their data without permission
    setLevelRec = (item, level) ->
      item.level = level
      maxLevel = if item.items? and item.items.length > 0
        Math.max(item.items.map( (item) -> setLevelRec(item, level + 1) )...)
      else
        level
      maxLevel
    setLevelRec(content, 0)

  _updatePosition: (left, top, property) ->
    style = "z-index: 1000; position: absolute; left: #{ left + 10 }px; top: #{ top + 2 }px;"
    @set(property, style)
    return

  data: () -> {
    visible:   false,
    target:    undefined,
    content:   undefined,
    menuData:  undefined,
    style:     'display: none;'
    submenus:  []
  }

  template: """
    <div class="ntb-popup" style="{{style}}">
      <ul class="ntb-list-menu">{{# content.items:itemNum }}
        {{> item }}
      {{/content.items }}</ul>
    </div>

    {{#submenus:num }}
      <div id="ntb-popup-{{ num }}" class="ntb-popup" style="{{ this.style }}">
        <ul class="ntb-list-menu">
          {{# this.item.items:itemNum }}
            {{> item }}
          {{/}}
        </ul>
      </div>
    {{/submenus }}

    {{#partial item }}
      {{#if items }}
        {{> group }}
      {{ else }}
        <li class="ntb-list-menu-item" on-click="[ 'exec', eventName, data ]">{{ name }}</li>
      {{/if }}
    {{/partial}}

    {{#partial group }}
      <li id="ntb-popup-{{level}}-{{itemNum}}" class="ntb-list-menu-item"
        on-mouseover="[ 'popup-submenu', this ]">{{ name }} ▶</li>
    {{/partial}}
  """
})

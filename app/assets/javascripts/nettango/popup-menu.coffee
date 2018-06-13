window.RactivePopupMenu = Ractive.extend({

  # The `content` for a popup menu should be of an `Items` type - the `name` will be ignored for the `content`
  # Content = Item | Items
  # Items { name: String, eventName: String, items: Array[Content] }
  # Item { name: String, eventName: String, data: POJO  }
  # The `eventName` string is optional for an Item - if not given the event on the parent Items will be used

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

    'popup-submenu': ({ event: { pageX, pageY } }, item, itemNum) ->
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
    maxLevel = 0
    setLevelRec = (item, level) ->
      if level > maxLevel then maxLevel = level
      item.level = level
      if item.items
        item.items.forEach( (item) -> setLevelRec(item, level + 1) )
    setLevelRec(content, 0)
    return maxLevel

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

    {{#partial group }}
      <li id="ntb-popup-{{level}}-{{itemNum}}" class="ntb-list-menu-item"
        on-mouseover="[ 'popup-submenu', this, itemNum ]">{{ name }} ▶</li>
    {{/partial}}

    {{#partial item }}
      {{#if items }}
        {{> group }}
      {{ else }}
        <li class="ntb-list-menu-item" on-click="[ 'exec', eventName, data ]">{{ name }}</li>
      {{/if }}
    {{/partial}}
  """
})

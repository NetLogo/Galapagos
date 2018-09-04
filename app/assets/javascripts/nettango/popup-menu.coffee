window.RactivePopupMenu = Ractive.extend({

  data: () -> {
    visible:   false,     # Boolean
    target:    undefined, # String
    content:   undefined, # Content
    menuData:  undefined, # Any
    left:      0,         # Number
    top:       0,         # Number
    class:     "",        # String
    submenus:  []         # Array[{ left: Number, top: Number, class: String, item: Content }]
  }

  # The `content` for a popup menu should be of an `Items` type - the `name` will be ignored for the `content`
  # Content = Item | Items
  # Item    = { name: String, eventName: String, data: Any  }
  # Items   = { name: String, eventName: String, items: Array[Content] }
  # The `eventName` string is optional for an Item - if not given the event on the root `content` will be used
  # The `menuData` (if sent via the `popup()` method) and the `data` for each item will be passed to the fired event
  # -JMB August 2018

  on: {

    # (Context, String, Any) => Unit
    'exec': (_, eventName, itemData) ->
      target   = @get('target')
      event    = eventName ? @get('content').eventName
      menuData = @get('menuData')
      if (menuData?)
        target.fire(event, {}, menuData, itemData)
      else
        target.fire(event, {}, itemData)
      return

    # (Context, Content, Integer, Integer) => Unit
    'popup-submenu': (_, item, level, itemNum) ->
      @set("submenus[#{item.level}].item", item)

      parentMenu = @find("#ntb-popup-#{ if level is 1 then 'root' else level - 1}")
      left = parentMenu.offsetLeft + (parentMenu.offsetWidth / 2)

      parentItem = @find("#ntb-popup-#{level}-#{itemNum}")
      top = parentMenu.offsetTop + parentItem.offsetTop + (parentItem.offsetHeight / 3)

      @_updatePosition(left, top, "submenus[#{item.level}].")
      return

  }

  # (String, Number, Number, Content, Any) => Unit
  popup: (target, left, top, content, menuData) ->
    maxLevel = @_markContent(content)
    submenus = for num in [1..maxLevel]
      { left: 0, top: 0, class: "" }
    @set('submenus', submenus)
    @set('menuData', menuData)
    @set('content',  content)
    @set('target',   target)
    @_updatePosition(left, top, "")
    return

  # () => Unit
  unpop: () ->
    @set('class', "")
    @get('submenus').forEach( (_, level) =>
      @set("submenus[#{level}].class", "")
    )
    return

  # (Content) => Integer
  _markContent: (content) ->
    # tag all the content levels with ID numbers, build a total ID array so we can create
    # a collection of popup menu levels - JMB August 2018
    setLevelRec = (item, level) ->
      item.level = level
      maxLevel = if item.items? and item.items.length > 0
        Math.max(item.items.map( (item) -> setLevelRec(item, level + 1) )...)
      else
        level
      maxLevel
    setLevelRec(content, 0)

  # (Number, Number, String) => Unit
  _updatePosition: (left, top, prefix) ->
    @set("#{prefix}left",  left + 10)
    @set("#{prefix}top",   top  + 2)
    @set("#{prefix}class", 'ntb-popup-active')
    return

  template: """
    <div id="ntb-popup-root" class="ntb-popup {{ class }}" style="left: {{ left }}px; top: {{ top }}px;">
      <ul class="ntb-list-menu">{{# content.items:itemNum }}
        {{> item }}
      {{/content.items }}</ul>
    </div>

    {{#submenus:num }}
      <div id="ntb-popup-{{ num }}" class="ntb-popup {{ class }}" style="left: {{ left }}px; top: {{ top }}px;">
        <ul class="ntb-list-menu">
          <li>{{ this.item.name }}</li>
          {{# this.item.items:itemNum }}
            {{> item }}
          {{/}}
        </ul>
      </div>
    {{/submenus }}

    {{#partial item }}
      {{# items !== undefined }}
        {{> group }}
      {{ else }}
        <li class="ntb-list-menu-item" on-click="[ 'exec', eventName, data ]">{{ name }}</li>
      {{/}}
    {{/partial}}

    {{#partial group }}
      <li id="ntb-popup-{{level}}-{{itemNum}}" class="ntb-list-submenu"
        on-mouseover="[ 'popup-submenu', this, level, itemNum ]">{{ name }} ▶</li>
    {{/partial}}
  """
})

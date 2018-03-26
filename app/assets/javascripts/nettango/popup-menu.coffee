window.RactivePopupMenu = Ractive.extend({
  on: {
    'exec': (_, tag, groupId, itemNum) ->
      content = @get('content')
      @fire(content[groupId].items[itemNum].event ? content.event, tag, groupId, itemNum)
  }

  observe: {
    'elementId': (value) ->
      @updatePosition(value)
      return

    'visible': (value) ->
      if (!value)
        @set('style', "display: none;")
      else
        @updatePosition(@get('elementId'))
      return
  }

  updatePosition: (elementId) ->
    element = document.getElementById(elementId)
    if(element)
      # for this to work, both the element and the popup menu must be in the same relative parent.
      @set('style', "z-index: 1000;position:absolute;left:#{ element.offsetLeft + 18 }px;top:#{ element.offsetTop + 18 }px;")
    return

  data: () -> {
    visible:   false,
    # if event is set on the item, use that, else use the content event
    content:   undefined, # { event, groupId: { name, event, items: [ { event, action } ] }
    elementId: undefined,
    tag:       undefined,
    style:     "left: 24px;z-index: 1000;position:fixed;"
  }

  template: """
    <div class="ntb-popup" style="{{style}}">
      <ul class="ntb-list-menu">{{#content:groupId }}
        <li class="ntb-list-menu-title">{{ name }}</li>
        {{#items:itemNum }}
          <li class="ntb-list-menu-item" on-click="[ 'exec', tag, groupId, itemNum ]" >{{ action }}</li>
        {{/items }}
        <li class="ntb-list-menu-spacer"></li>
      {{/content }}</ul>
    </div>
  """
})

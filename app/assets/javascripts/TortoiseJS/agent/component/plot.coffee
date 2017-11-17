window.RactivePlot = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).deleteAndRecompile]
  , menuIsOpen:         false
  }

  on: {
    render: ->
      ractive          = this
      topLevel         = document.querySelector("##{@get('id')}")
      topLevelObserver = new MutationObserver(
        (mutations) -> mutations.forEach(
          ({ addedNodes }) ->
            container = Array.from(addedNodes).find((elem) -> elem.classList.contains("highcharts-container"))
            if container?
              topLevelObserver.disconnect()
              containerObserver = new MutationObserver(
                (mutties) -> mutties.forEach(
                  ({ addedNodes: addedNodies }) ->
                    menu = Array.from(addedNodies).find((elem) -> elem.classList.contains("highcharts-contextmenu"))
                    if menu?
                      ractive.set('menuIsOpen', true)
                      containerObserver.disconnect()
                      menuObserver = new MutationObserver(-> ractive.set('menuIsOpen', menu.style.display isnt "none"))
                      menuObserver.observe(menu, { attributes: true })
                )
              )
              containerObserver.observe(container, { childList: true })
        )
      )
      topLevelObserver.observe(topLevel, { childList: true })
  }

  # coffeelint: disable=max_line_length
  template:
    """
    <div id="{{id}}"
         on-contextmenu="@this.fire('showContextMenu', @event)" on-click="@this.fire('selectWidget', @event)"
         {{ #isEditing }} draggable="true" on-drag="dragWidget" on-dragstart="startWidgetDrag" on-dragend="stopWidgetDrag" {{/}}
         class="netlogo-widget netlogo-plot{{#isEditing}} interface-unlocked{{/}}"
         style="{{dims}}{{#menuIsOpen}}z-index: 10;{{/}}{{ #isEditing }}padding: 10px;{{/}}"></div>
    """
  # coffeelint: enable=max_line_length

})

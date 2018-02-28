window.RactivePlot = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).delete]
  , isNotEditable:      true
  , menuIsOpen:         false
  , resizeCallback:     ((x, y) ->)
  }

  observe: {
    'left right top bottom': ->
      @get('resizeCallback')(@get('right') - @get('left'), @get('bottom') - @get('top'))
      return
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
    <div id="{{id}}" class="netlogo-widget netlogo-plot{{#isEditing}} interface-unlocked{{/}}"
         style="{{dims}}{{#menuIsOpen}}z-index: 10;{{/}}"></div>
    {{>editorOverlay}}
    """
  # coffeelint: enable=max_line_length

})

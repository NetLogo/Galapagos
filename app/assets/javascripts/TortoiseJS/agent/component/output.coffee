window.RactiveOutputArea = Ractive.extend({
  data: {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # OutputWidget
  , output: undefined # String
  }

  isolated: true

  components: {
    printArea: RactivePrintArea
  }

  template:
    """
    <div id="{{id}}"
         on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
         class="netlogo-widget netlogo-output netlogo-output-widget" style="{{dims}}">
      <printArea id="{{id}}-print-area" output="{{output}}" />
    </div>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item">Nothing to see here</li>
      </ul>
    </div>
    """

})

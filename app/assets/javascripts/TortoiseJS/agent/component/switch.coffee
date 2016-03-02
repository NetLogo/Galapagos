window.RactiveSwitch = Ractive.extend({
  data: {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # SwitchWidget
  }

  isolated: true

  template:
    """
    <label id="{{id}}"
           on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
           class="netlogo-widget netlogo-switcher netlogo-input"
           style="{{dims}}">
      <input type="checkbox" checked={{ widget.currentValue }} />
      <span class="netlogo-label">{{ widget.display }}</span>
    </label>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item">Nothing to see here</li>
      </ul>
    </div>
    """

})

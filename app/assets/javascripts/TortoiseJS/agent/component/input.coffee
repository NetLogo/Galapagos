window.RactiveInput = Ractive.extend({
  data: {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # InputWidget
  }

  isolated: true

  template:
    """
    <label id="{{id}}"
           on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
           class="netlogo-widget netlogo-input-box netlogo-input"
           style="{{dims}}">
      <div class="netlogo-label">{{widget.varName}}</div>
      {{# widget.boxtype === 'Number'}}<input type="number" value="{{widget.currentValue}}" />{{/}}
      {{# widget.boxtype === 'String'}}
        {{#if widget.multiline === false}}
          <input type="text" value="{{widget.currentValue}}" />
        {{else}}
          <textarea class="netlogo-multiline-input">{{widget.currentValue}}</textarea>
        {{/if}}
      {{/}}
      {{# widget.boxtype === 'String (reporter)'}}<input type="text" value="{{widget.currentValue}}" />{{/}}
      {{# widget.boxtype === 'String (commands)'}}<input type="text" value="{{widget.currentValue}}" />{{/}}
      <!-- TODO: Fix color input. It'd be nice to use html5s color input. -->
      {{# widget.boxtype === 'Color'}}<input type="color" value="{{widget.currentValue}}" />{{/}}
    </label>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
      </ul>
    </div>
    """

})

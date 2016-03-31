window.RactiveChooser = Ractive.extend({
  data: -> {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # ChooserWidget
  }

  isolated: true

  template:
    """
    <label id="{{id}}"
           on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
           class="netlogo-widget netlogo-chooser netlogo-input"
           style="{{dims}}">
      <span class="netlogo-label">{{widget.display}}</span>
      <select class="netlogo-chooser-select" value="{{widget.currentValue}}">
      {{#widget.choices}}
        <option class="netlogo-chooser-option" value="{{.}}">{{>literal}}</option>
      {{/}}
      </select>
    </label>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
      </ul>
    </div>
    """

  partials: {

    literal:
      """
      {{# typeof . === "string"}}{{.}}{{/}}
      {{# typeof . === "number"}}{{.}}{{/}}
      {{# typeof . === "object"}}
        [{{#.}}
          {{>literal}}
        {{/}}]
      {{/}}
      """

  }

})

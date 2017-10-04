window.RactiveChooser = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  }

  template:
    """
    <label id="{{id}}"
           on-contextmenu="@this.fire('showContextMenu', @event)"
           class="netlogo-widget netlogo-chooser netlogo-input"
           style="{{dims}}">
      <span class="netlogo-label">{{widget.display}}</span>
      <select class="netlogo-chooser-select" value="{{widget.currentValue}}">
      {{#widget.choices}}
        <option class="netlogo-chooser-option" value="{{.}}">{{>literal}}</option>
      {{/}}
      </select>
    </label>
    """

  partials: {

    literal:
      """
      {{# typeof . === "string"}}{{.}}{{/}}
      {{# typeof . === "number"}}{{.}}{{/}}
      {{# typeof . === "boolean"}}{{.}}{{/}}
      {{# typeof . === "object"}}
        [{{#.}}
          {{>literal}}
        {{/}}]
      {{/}}
      """

  }

})

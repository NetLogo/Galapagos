window.RactiveEditFormLabeledInput = Ractive.extend({

  data: -> {
    attrs:      undefined # String
  , class:      undefined # String
  , id:         undefined # String
  , labelStr:   undefined # String
  , labelStyle: undefined # String
  , name:       undefined # String
  , style:      undefined # String
  , type:       undefined # String
  , value:      undefined # String
  }

  twoway: false

  template:
    """
    <div class="flex-row" style="align-items: center;">
      <label for="{{id}}" class="widget-edit-input-label" style="{{labelStyle}}">{{labelStr}}</label>
      <div style="flex-grow: 1;">
        <input class="widget-edit-text widget-edit-input {{class}}" id="{{id}}" name="{{name}}"
               type="{{type}}" value="{{value}}" style="{{style}}" {{attrs}} />
      </div>
    </div>
    """

})

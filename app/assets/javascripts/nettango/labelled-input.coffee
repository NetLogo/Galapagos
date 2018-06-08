window.RactiveLabelledInput = Ractive.extend({
  data: () -> {
    style: undefined # String
    id:    undefined # String
    value: undefined # Any
    type:  undefined # String
    name:  undefined # String
    label: undefined # String
  }

  template:
    """
    <div style="flex: column; padding: 0px;{{ style }}">
      <label for="{{ id }}">{{ label }}</label>
      <input id="{{ id }}" name="{{ name }}" type="{{ type }}" value="{{ value }}"
        class="widget-edit-inputbox" style="margin: 0px; width: 90%; min-width: 30px;" lazy />
    </div>
    """
})

window.RactiveArrayView = Ractive.extend({

  data: () -> {

    id:              undefined      # String
    itemType:        undefined      # String
    itemTypePlural:  undefined      # String
    createItem:      undefined      # (Number) => Any
    itemAddEvent:    "item-added"   # String
    itemRemoveEvent: "item-removed" # String
    items:           undefined      # Array[Any]
    itemTemplate:    undefined      # String

  }

  on: {
    'complete': (_) ->
      @resetPartial("item-template", @get('itemTemplate'))
      return

    'add-item': () ->
      number   = @get("items.length")
      creator  = @get("createItem")
      addEvent = @get("itemAddEvent")
      @push("items", creator(number))
      @fire(addEvent)
      return

    'remove-item': (_, number) ->
      removeEvent = @get("itemRemoveEvent")
      @splice("items", number, 1)
      @fire(removeEvent, number)
      return
  }

  template:
    """
    {{#partial item-template}}Unset{{/partial}}

    <div id="{{ id }}" class="flex-column">
      <div class="ntb-block-defs-controls">
        <label>{{ itemTypePlural }}</label>
        <button class="ntb-button" type="button" on-click="[ 'add-item' ]">Add {{ itemType }}</button>
      </div>
      {{# items:number }}
        {{> item-template }}
        <div>
          <button class="ntb-button" type="button" on-click="[ 'remove-item', number ]">Delete {{ itemType }} {{ number }}</button>
        </div>
      {{/items }}
    </div>
    """
})

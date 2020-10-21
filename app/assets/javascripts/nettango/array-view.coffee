window.RactiveArrayView = (partials, components) -> RactiveToggle.extend({

  data: () -> {

    id:                undefined      # String
    itemType:          undefined      # String
    itemTypePlural:    undefined      # String
    createItem:        undefined      # (Number) => Any
    itemAddEvent:      "item-added"   # String
    itemRemoveEvent:   "item-removed" # String
    items:             undefined      # Array[Any]
    itemsWrapperClass: undefined      # String
    viewClass:         undefined      # String
    headerItem:        {}             # Any

  }

  on: {

    'add-item': () ->
      number   = @get("items.length")
      creator  = @get("createItem")
      addEvent = @get("itemAddEvent")
      @push("items", creator(number))
      @set("show", true)
      @fire(addEvent)
      return

    'remove-item': (_, number) ->
      removeEvent = @get("itemRemoveEvent")
      @splice("items", number, 1)
      @fire(removeEvent, number)
      return

  }

  components: components

  # coffeelint: disable=max_line_length
  partials: Object.assign({

    deleteButton:
      """<button class="ntb-button" type="button" on-click="[ 'remove-item', number ]">Delete</button>"""

  , headerTemplate: ""

  , itemTemplate:   "Item template unset, probably a mistake, yeah?"

  , titleTemplate:
    """{{ itemTypePlural }} <button class="ntb-button" type="button" on-click="[ 'add-item' ]">Add {{ itemType }}</button>"""

  , contentTemplate:
    """
    <div class="{{ itemsWrapperClass }}">

      {{# headerItem }}
        {{> headerTemplate }}
      {{/ headerItem }}

      {{# items:number }}
        {{> itemTemplate }}
      {{/ items }}

    </div>
    """

  }, partials)
  # coffeelint: enable=max_line_length

})

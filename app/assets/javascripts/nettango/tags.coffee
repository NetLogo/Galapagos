window.RactiveTags = Ractive.extend({

  data: () -> {
      tags:         [] # Array[String]
    , knownTags:    [] # Array[String]
    , filter:       '' # String
    , selectedTags: [] # Array[String]
  }

  computed: {

    unselectedTags: () ->
      knownTags = @get('knownTags')
      tags      = @get('tags')
      knownTags.filter( (tag) -> not tags.includes(tag) )

    filteredTags: () ->
      tags     = @get('unselectedTags')
      filter   = @get('filter').toLowerCase()
      filtered = tags.filter( (t) -> t.toLowerCase().includes(filter) )
      filtered.sort( @compareStrings )

    isExistingTag: () ->
      knownTags = @get('knownTags')
      filter    = @get('filter').toLowerCase()
      knownTags.filter( (t) -> t.toLowerCase() is filter ).length isnt 0

    workspaceSize: () ->
      filteredTags = @get('filteredTags')
      Math.min(10, Math.max(3, filteredTags.length))

  }

  observe: {

    'filter': () ->
      filteredTags = @get('filteredTags')
      if filteredTags.length is 0
        @set('selectedTags', [])
        return

      selectedTags = @get('selectedTags')
      filteredSelectedTags = selectedTags.filter( (t) -> filteredTags.includes(t) )
      @set('selectedTags', filteredSelectedTags)
      if filteredSelectedTags.length isnt 0
        return

      filter = @get('filter')
      if filter is ''
        return

      @push('selectedTags', filteredTags[0])
      return

  }

  on: {

    '*.check-for-enter-press': (context) ->
      if context.event.keyCode isnt 13
        return true

      selectedTags = @get('selectedTags')
      if selectedTags.length isnt 0
        @addSelectedTags(selectedTags)

      else
        isExistingTag = @get('isExistingTag')
        filter = @get('filter')
        if not isExistingTag and filter isnt ''
          @addNewTag(filter)

      context.event.preventDefault()
      false

    '*.check-for-up-or-down-press': (context) ->
      if context.event.keyCode is 38
        @moveSelection(
          (arr, index) -> index isnt 0,
          (index) -> index - 1
          )
        return

      if context.event.keyCode is 40
        @moveSelection(
          (arr, index) -> index isnt( arr.length - 1) ,
          (index) -> index + 1
        )
        return

      return

    '*.add-clicked-tag': (_, tag) ->
      @addTag(tag)
      return

    '*.add-new-tag': () ->
      @addNewTag(@get('filter'))
      return

    '*.add-selected-tags': () ->
      @addSelectedTags(@get('selectedTags'))
      return

    '*.remove-tag': (_, tag) ->
      tags = @get('tags').filter( (t) -> t isnt tag )
      @set('tags', tags)
      return false

  }

  compareStrings: (t1, t2) ->
    t1.localeCompare(t2)

  addTag: (tag) ->
    @push('tags', tag)
    @set('selectedTags', [])
    return

  addSelectedTags: (selectedTags) ->
    @push('tags', ...selectedTags)
    @set('selectedTags', [])
    @set('filter', '')
    return

  addNewTag: (filter) ->
    @push('knownTags', filter)
    @push('tags',      filter)
    @set('filter', '')
    return

  moveSelection: (isMovable, getNextIndex) ->
    selectedTags = @get('selectedTags')
    if selectedTags.length isnt 1
      return

    filteredTags = @get('filteredTags')
    if filteredTags.length <= 1
      return

    tag = selectedTags[0]
    tagIndex = filteredTags.indexOf(tag)
    if not isMovable(tagIndex, filteredTags)
      return

    newSelectedTag = filteredTags[getNextIndex(tagIndex)]
    @set('selectedTags', [newSelectedTag])
    return

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-tag-cloud flex-row">
      {{#each tags.sort( compareStrings ) }}
        <div class="ntb-tag">{{this}} <button class="ntb-button" on-click='[ 'remove-tag', this ]'>x</button></div>
      {{else}}
        <div class="ntb-tag-cloud-empty">No tags applied</div>
      {{/each}}
    </div>

    <div class="ntb-tag-controls flex-row">

      <input class="ntb-tag-filter" type="text"
        value={{ filter }}
        on-keydown="check-for-enter-press"
        on-keyup="check-for-up-or-down-press"
        placeholder="Filter available tags or enter new tag name"
      />

      <button class="ntb-button ntb-tag-button" type="button"
        disabled={{ selectedTags.length === 0 }}
        on-click="add-selected-tags">
        Add Selected Tags
      </button>

      <button class="ntb-button ntb-tag-button" type="button"
        disabled={{ isExistingTag || filter === '' }}
        on-click="add-new-tag">
        Add New Tag
      </button>

    </div>

    <label class="ntb-tag-options-label" for="workspace-tags">Available Tags</label>

    <select class="ntb-tag-options" multiple size={{ workspaceSize }} value={{ selectedTags }}>

      {{#each filteredTags }}
        <option value="{{this}}" on-dblclick='[ 'add-clicked-tag', this ]'>{{this}}</option>
      {{else}}
        <option disabled value>All available tags are applied</option>
      {{/each}}

    </select>
    """
    # coffeelint: enable=max_line_length

})

window.RactiveToggleTags = RactiveToggle.extend({

  on: {
    '*.clear-tags': () ->
      tags = @get('tags')
      @splice('tags', 0, tags.length)
      return
  }

  partials: {

    contentTemplate:
      """<tags tags={{ tags }} knownTags={{ knownTags }} />"""

  , titleTemplate:
      """Tags <button class="ntb-button" type="button" on-click="clear-tags">Clear Tags</button>"""

  }

  components: { tags: RactiveTags }

})

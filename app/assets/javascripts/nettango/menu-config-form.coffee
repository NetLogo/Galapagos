import { RactiveTwoWayLabeledInput } from "/beak/widgets/ractives/subcomponent/labeled-input.js"
import RactiveArrayView from "./array-view.js"
import RactiveModalDialog from "./modal-dialog.js"
import RactiveTagGroupSettings from "./tag-group-settings.js"
import ObjectUtils from "./object-utils.js"

partials = {

  headerTemplate: """
    <labeledInput
      id       = "tag-group-header"
      name     = "header"
      type     = "text"
      value    = "{{ header }}"
      labelStr = "Main menu header"
      divClass = "ntb-flex-column"
      class    = "ntb-input"
      />
    """

  itemTemplate: """
    <tagGroupSettings
      tagGroup    = {{ this }}
      groupIndex  = {{ number }}
      showAtStart = {{ number === selectedGroupIndex }}
      knownTags   = {{ knownTags }}
      />
    """

}

RactiveMenuConfigForm = RactiveModalDialog.extend({
  data: () -> {
    deny:               { text: "Discard Changes" }
    containerId:        undefined # String
    menuConfig:         undefined # NetTangoMenuConfig
    selectedGroupIndex: undefined # Int
    knownTags:          []        # String[]

    createTagGroup:
      (number) ->
        @set('selectedGroupIndex', number)
        {
          header:      "Group #{number}"
        , isCollapsed: false
        , order:       []
        , tags:        []
        }

  }

  show: (left, top, applyTarget, containerId, menuConfig, selectedGroupIndex) ->
    @set('containerId', containerId)
    @set('menuConfig', ObjectUtils.clone(menuConfig))
    @set('selectedGroupIndex', selectedGroupIndex)

    @set('approve', {
      text:      "Apply Menu Groups"
    , event:     "ntb-menu-config-updated"
    , argsMaker: (() => [@get('containerId'), @get('menuConfig')])
    , target:    applyTarget
    })

    @_super(top, left)
    return

  components: {
    menuConfigControl: RactiveArrayView(partials, {
      labeledInput: RactiveTwoWayLabeledInput
    , tagGroupSettings:  RactiveTagGroupSettings
    })
  }

  partials: {

    headerContent: undefined

    dialogContent: """
      <menuConfigControl
        headerItem         = {{ menuConfig.mainGroup }}
        items              = {{ menuConfig.tagGroups }}
        knownTags          = {{ knownTags }}
        selectedGroupIndex = {{ selectedGroupIndex }}
        itemType           = "Tag Group"
        itemTypePlural     = "Menu Groups"
        createItem         = {{ createTagGroup }}
        viewClass          = "ntb-block-array"
        showAtStart        = true
        enableToggle       = false
        />
      """
  }
})

export default RactiveMenuConfigForm

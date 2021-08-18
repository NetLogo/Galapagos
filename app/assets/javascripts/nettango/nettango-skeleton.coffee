import RactiveBlockForm from "./block-form.js"
import RactiveBuilder from "./builder.js"
import RactiveBuilderMenu from "./builder-menu.js"
import RactiveConfirmDialog from "./confirm-dialog.js"
import RactiveMenuConfigForm from "./menu-config-form.js"
import RactiveModelChooser from "./model-chooser.js"
import RactiveNetLogoModel from "./netlogo-model.js"
import RactiveOptionsForm from "./options-form.js"
import RactivePopupMenu from "./popup-menu.js"
import RactiveProjectChooser from "./project-chooser.js"

# (HTMLElement, Environment, Boolean, Boolean) => Ractive
create = (element, playMode, runtimeMode, isDebugMode) ->
  new Ractive({

    el: element,

    data: () -> {
      breeds:       []          # Array[String]
      canRedo:      false       # Boolean
      canUndo:      false       # Boolean
      isDebugMode:  isDebugMode # Boolean
      isSideBySide: false       # Boolean
      playMode:     playMode    # Boolean
      runtimeMode:  runtimeMode # String
    }

    computed: {
      displayClass: () ->
        isSideBySide = @get('isSideBySide')
        if isSideBySide
          'netlogo-display-horizontal'
        else
          'netlogo-display-vertical'
    }

    on: {

      'complete': (_) ->
        popupMenu = @findComponent('popupMenu')
        document.addEventListener('click', (event) ->
          if event?.button isnt 2
            popupMenu.unpop()
        )
        return

      '*.show-confirm-dialog': ({ event: { pageY } }, options) ->
        confirmDialog = @findComponent('confirmDialog')
        options.top   = options?.top ? Math.max(pageY - 100, 50)
        confirmDialog.show(options)
        return

      '*.show-project-chooser': ({ event: { pageY } }) ->
        projectChooser = @findComponent('projectChooser')
        projectChooser.show(Math.max(pageY - 100, 50))
        return

      '*.show-model-chooser': ({ event: { pageY } }) ->
        modelChooser = @findComponent('modelChooser')
        modelChooser.show(Math.max(pageY - 100, 50))
        return

      '*.show-block-edit-form': (_, top, target, spaceName, block, blockIndex, submitLabel, submitEvent, cancelLabel) ->
        blockForm = @findComponent('blockEditForm')
        blockForm.show(top, target, spaceName, block, blockIndex, submitLabel, submitEvent, cancelLabel)
        return

      '*.show-group-edit-form': (_, top, containerId, groupIndex) ->
        builder        = @findComponent('builder')
        space          = builder.getSpace(containerId)
        menuConfig     = space.defs.menuConfig
        menuConfigForm = @findComponent('menuConfigForm')
        menuConfigForm.show(top, builder, containerId, menuConfig, groupIndex)
        return

      '*.show-options-form': () ->
        builder = @findComponent('builder')
        options = builder.assembleOptions()
        optionsForm = @findComponent("optionsForm")
        optionsForm.show(builder, options)
        return

      '*.show-popup-menu': (_, target, top, left, options, menuData) ->
        popupMenu = @findComponent('popupMenu')
        popupMenu.popup(target, top, left, options, menuData)
        return

      '*.ntb-clear-all': (_) ->
        builder = @findComponent('builder')
        builder.clearAll()
        return

      '*.ntb-create-blockspace': (_) ->
        builder = @findComponent('builder')
        builder.createSpace({ defs: { blocks: [], program: { chains: [] }}})
        return

    }

    components: {
      blockEditForm:  RactiveBlockForm
    , builder:        RactiveBuilder
    , builderMenu:    RactiveBuilderMenu
    , confirmDialog:  RactiveConfirmDialog
    , menuConfigForm: RactiveMenuConfigForm
    , modelChooser:   RactiveModelChooser
    , netLogoModel:   RactiveNetLogoModel
    , optionsForm:    RactiveOptionsForm
    , popupMenu:      RactivePopupMenu
    , projectChooser: RactiveProjectChooser
    },

    template:
      """
      <div class="ntb-components">

        <confirmDialog />
        <popupMenu />

        {{# !playMode }}
        <modelChooser runtimeMode="{{ runtimeMode }}" />
        <projectChooser />
        <blockEditForm blockStyles={{ blockStyles }} allTags={{ allTags }} />
        <menuConfigForm knownTags={{ allTags }} />
        <optionsForm />
        {{/}}

        {{# !playMode }}
        <builderMenu
          canUndo={{ canUndo }}
          canRedo={{ canRedo }}
          isDebugMode={{ isDebugMode }}
          runtimeMode={{ runtimeMode }}>
        />
        {{/}}

        <div class="ntb-models {{ displayClass }}">

          <netLogoModel />

          <builder
            playMode={{ playMode }}
            breeds={{ breeds }}
            isSideBySide={{ isSideBySide }}
            blockStyles={{ blockStyles }}
            allTags={{ allTags }}
          />

        </div>

      </div>
      """

  })

NetTangoSkeleton = { create }

export default NetTangoSkeleton

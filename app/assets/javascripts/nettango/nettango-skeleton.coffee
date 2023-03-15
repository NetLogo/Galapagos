import RactiveBlockForm from "./block-form.js"
import RactiveBuilder from "./builder.js"
import RactiveBuilderMenu from "./builder-menu.js"
import RactiveCodeMirror from "./code-mirror.js"
import RactiveConfirmDialog from "./confirm-dialog.js"
import RactiveMenuConfigForm from "./menu-config-form.js"
import RactiveModelChooser from "./model-chooser.js"
import RactiveNetLogoModel from "./netlogo-model.js"
import RactiveOptionsForm from "./options-form.js"
import RactivePopupMenu from "./popup-menu.js"
import RactiveProjectChooser from "./project-chooser.js"
import RactiveHelpDialog from "./help-dialog.js"

# (HTMLElement, String, Environment, Boolean, Boolean) => Ractive
create = (element, locale, playMode, runtimeMode, isDebugMode) ->
  ractive = new Ractive({

    el: element,

    data: () -> {
      locale:          locale      # String
      breeds:          []          # Array[String]
      canRedo:         false       # Boolean
      canUndo:         false       # Boolean
      isDebugMode:     isDebugMode # Boolean
      isSideBySide:    false       # Boolean
      playMode:        playMode    # Boolean
      runtimeMode:     runtimeMode # String
      codeTipsEnabled: true        # Boolean
      variables:       []          # Array[NetTangoVariable]
    }

    computed: {
      displayClass: () ->
        isSideBySide = @get('isSideBySide')
        if isSideBySide
          'ntb-models-horizontal'
        else
          'ntb-models-vertical'
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

      '*.show-help': ({ event: { pageY } }) ->
        builder = @findComponent('builder')
        @set('codeTipsEnabled', builder.get('codeTipsEnabled'))
        helpDialog = @findComponent('helpDialog')
        helpDialog.show(Math.max(pageY - 100, 50))
        return

      '*.ntb-clear-all': (_) ->
        builder = @findComponent('builder')
        builder.clearAll()
        return

      '*.ntb-create-blockspace': (_) ->
        builder = @findComponent('builder')
        builder.createSpace({ defs: { version: 7, blocks: [], program: { chains: [] }, chainClose: "end" }})
        return

    }

    components: {
      blockEditForm:  RactiveBlockForm
    , builder:        RactiveBuilder
    , builderMenu:    RactiveBuilderMenu
    , confirmDialog:  RactiveConfirmDialog
    , helpDialog:     RactiveHelpDialog
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

        {{! This weird `playMode` thing is to get around a bug where the `complete` event fires for the skeleton
            as soon as the `builderMenu` renders which is odd.  I can't see anything unique about the builder
            menu to cause this, so we just workaround for now.  -Jeremy B September 2021 }}
        {{# playMode || !playMode }}
        <builderMenu
          canUndo={{ canUndo }}
          canRedo={{ canRedo }}
          isDebugMode={{ isDebugMode }}
          playMode={{ playMode }}
          runtimeMode={{ runtimeMode }}
          />
        {{/ playMode }}

        <confirmDialog />
        <popupMenu />
        <helpDialog
          playMode={{ playMode }}
          codeTipsEnabled={{ codeTipsEnabled }}
          />

        {{# !playMode }}
        <modelChooser runtimeMode="{{ runtimeMode }}" />
        <projectChooser />
        <blockEditForm blockStyles={{ blockStyles }} allTags={{ allTags }} />
        <menuConfigForm knownTags={{ allTags }} />
        <optionsForm />
        {{/}}

        <div class="ntb-models {{ displayClass }}">

          <netLogoModel
            locale={{ locale }}
            />

          <builder
            playMode={{ playMode }}
            breeds={{ breeds }}
            variables={{ variables }}
            isSideBySide={{ isSideBySide }}
            blockStyles={{ blockStyles }}
            allTags={{ allTags }}
            />

        </div>

      </div>
      """

  })

  highlighters = new Map()
  NetTango.setSyntaxHighlighter( (elementId, code) ->
    if not highlighters.has(elementId)
      highlighters.set(elementId, new RactiveCodeMirror({
        el: "#{elementId}"
        data: () -> {
          id: "#{elementId}-codemirror"
        , mode: "netlogo"
        , code: code
        , config: { readOnly: 'nocursor' }
        , extraClasses: ['ntb-code-readonly']
        }
      }))
    highlighter = highlighters.get(elementId)
    highlighter.set('code', code)
  )

  ractive

NetTangoSkeleton = { create }

export default NetTangoSkeleton

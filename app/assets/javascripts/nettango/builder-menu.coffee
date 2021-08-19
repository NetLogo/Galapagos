sampleProjectUrl =
  "assets/nt-modelslib/Biology/Wolves and Sheep.ntjson"

RactiveBuilderMenu = Ractive.extend({

  data: () -> {
    canUndo:     false     # Boolean
    canRedo:     false     # Boolean
    isDebugMode: false     # Boolean
    runtimeMode: "dev"     # String
  }

  on: {

    'ntb-show-file-operations': ({ event: { pageX, pageY } }) ->
      items = [
        { eventName: 'ntb-clear-all-check', name: 'Clear model and spaces' }
        { spacerText: '-' }

        { eventName: 'ntb-import-json-prompt',   name: 'Import NetTango project' }
        { eventName: 'ntb-load-remote-project',  name: 'Load Wolves and Sheep sample project', data: sampleProjectUrl }
        { eventName: 'show-project-chooser', name: 'Choose NetTango library project' }
        { spacerText: '-' }

        { eventName: 'ntb-import-netlogo-prompt', name: 'Import NetLogo model' }
        { eventName: 'show-model-chooser', name: 'Choose NetLogo library model' }
        { spacerText: '-' }

        { eventName: 'ntb-export-json', name: 'Export NetTango project' }
        { eventName: 'ntb-export-page', name: 'Export standalone HTML file' }
        { name: 'Preview standalone HTML page', url: '/nettango-player?playMode=true' }
        { spacerText: '-' }

        { eventName: 'ntb-export-netlogo', name: 'Export NetLogo model' }
      ]
      fileOperations = {
        items: items
      }
      @fire('show-popup-menu', {}, this, pageX, pageY, fileOperations)
      return false

    'ntb-show-help': ({ event: { pageX, pageY } }) ->
      helpOptions = {
        items: [
          {
              name: 'About the NetTango Web Builder'
            , url: 'https://github.com/NetLogo/Galapagos/wiki/NetTango-Builder'
          }
          {
              name: 'NetTango Web Builder tutorial'
            , url: 'https://anttango.netlify.com'
          }
        ]
      }

      if @get('runtimeMode') is 'dev'
        helpOptions.items.push({
            name: 'Toggle web console debug'
          , eventName: 'ntb-toggle-debug'
        })

      @fire('show-popup-menu', {}, this, pageX, pageY, helpOptions)
      return false

    'ntb-toggle-debug': () ->
      @set('isDebugMode', not @get('isDebugMode'))
      return

    # (Context) => Unit
    '*.ntb-clear-all-check': (context) ->
      @fire('show-confirm-dialog', context, {
        text:    "Do you want to clear your model and workspaces?"
      , approve: { text: "Yes, clear all data", event: "ntb-clear-all" }
      , deny:    { text: "No, leave workspaces unchanged" }
      })
      return

    '*.ntb-import-netlogo-prompt': (_) ->
      importInput = @find('#ntb-import-netlogo')
      importInput.value = ""
      importInput.click()
      return

    '*.ntb-import-json-prompt': (_) ->
      importInput = @find('#ntb-import-json')
      importInput.value = ""
      importInput.click()
      return
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <input id="ntb-import-json"    class="ntb-file-button" type="file" on-change="ntb-import-project" hidden>
    <input id="ntb-import-netlogo" class="ntb-file-button" type="file" on-change="ntb-import-netlogo" hidden>

    <div class="ntb-menu-controls ntb-block-defs-controls">
      <div class="ntb-title">NetTango Web Builder</div>
      <button class="ntb-button" type="button" on-click="ntb-show-file-operations">Files ▼</button>
      <button class="ntb-button" type="button" on-click="ntb-undo"{{# !canUndo }} disabled{{/}}>Undo</button>
      <button class="ntb-button" type="button" on-click="ntb-redo"{{# !canRedo }} disabled{{/}}>Redo</button>
      <button class="ntb-button" type="button" on-click="show-options-form">Options...</button>
      <button class="ntb-button" type="button" on-click="ntb-create-blockspace" >Add New Block Space</button>
      <button class="ntb-button" type="button" on-click="ntb-show-help">Help ▼</button>
    </div>
    """
})

export default RactiveBuilderMenu

window.RactiveBuilderMenu = Ractive.extend({

  data: () -> {
    popupMenu: undefined # RactivePopupMenu
    canUndo:   false     # Boolean
    canRedo:   false     # Boolean
  }

  on: {
    'ntb-show-file-operations': ({ event: { pageX, pageY } }) ->
      popupMenu = @get("popupMenu")
      fileOperations = {
        name: "File Operations"
        items: [
          { eventName: 'ntb-clear-all-check',       name: 'Clear model and spaces' }
          { spacerText: '-' }
          { eventName: 'ntb-import-json-prompt',    name: 'Import NetTango project' }
          { spacerText: '-' }
          { eventName: 'ntb-import-netlogo-prompt', name: 'Import NetLogo model' }
          { eventName: 'ntb-choose-netlogo-prompt', name: 'Choose NetLogo library model' }
          { spacerText: '-' }
          { eventName: 'ntb-export-json',           name: 'Export NetTango project' }
          { eventName: 'ntb-export-page',           name: 'Export standalone HTML file' }
          { name: 'Preview standalone HTML page', url: '/ntango-play?playMode=true' }
          { spacerText: '-' }
          { eventName: 'ntb-export-netlogo',        name: 'Export NetLogo model' }
        ]
      }
      popupMenu.popup(this, pageX, pageY, fileOperations)
      return false

    'ntb-show-help': ({ event: { pageX, pageY } }) ->
      popupMenu = @get("popupMenu")
      helpOptions = {
        name: "Help"
        items: [
          {
              name: 'About the NetTango Builder'
            , url: 'https://github.com/NetLogo/Galapagos/wiki/NetTango-Builder'
          }
          {
              name: 'NetTango Builder tutorial'
            , url: 'https://anttango.netlify.com'
          }
        ]
      }
      popupMenu.popup(this, pageX, pageY, helpOptions)
      return false

  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-block-defs-controls">
      <button class="ntb-button" type="button" on-click="ntb-show-file-operations">Files ▼</button>
      <button class="ntb-button" type="button" on-click="ntb-undo"{{# !canUndo }} disabled{{/}}>Undo</button>
      <button class="ntb-button" type="button" on-click="ntb-redo"{{# !canRedo }} disabled{{/}}>Redo</button>
      <button class="ntb-button" type="button" on-click="ntb-show-options">Options...</button>
      <button class="ntb-button" type="button" on-click="ntb-create-blockspace" >Add New Block Space</button>
      <button class="ntb-button" type="button" on-click="ntb-show-help">Help ▼</button>
    </div>
    """
})

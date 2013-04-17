$globals = exports.$ChatGlobals
UI       = exports.ChatServices.UI

commandCenterInit = ->

  # Due to the way Ace is set up, getting this to work with modes/themes that have version numbers is somewhat of a pain
  editor = ace.edit("codeBufferWrapper")
  editor.setTheme("ace/theme/netlogo-classic")
  editor.getSession().setMode("ace/mode/netlogo")
  editor.renderer.setShowGutter(false)
  editor.setShowPrintMargin(false)
  editor.setFontSize("14px")
  exports.ChatGlobals.ccEditor = editor

  # Restyle it from being a multiline editor to being a single-line editor
  id = "inputBuffer"

  $wrapper  = $("#codeBufferWrapper")
  $scroller = $wrapper.children(".ace_scroller")
  $content  = $scroller.children(".ace_content")

  $wrapper.children(".ace_scrollbar").css("display", "none")
  $wrapper.children(".ace_text-input").attr("id", id)

  # On resize, this overrides the (re)insertion of the margin for the vertical scrollbar
  onResize_ = editor.renderer.onResize
  editor.renderer.onResize = ->
    onResize_.apply(editor.renderer, arguments) # Forward the call to the original function
    $scroller.css("right", "0px")

  # Get things colored correctly when the editor rerenders to accommodate for big changes
  $renderChanges_ = editor.renderer.$renderChanges
  editor.renderer.$renderChanges = ->
    $renderChanges_.apply(editor.renderer, arguments)
    tryColoring = ->
      BGColorPropName = 'background-color'
      color = $scroller.children(".ace_content").children(".ace_marker-layer").children(".ace_active-line").css(BGColorPropName)
      if color is "rgba(0, 0, 0, 0)" or color is "transparent"
        return
      else if not color # If Ace is still initializing, we can try again in 100ms
        setTimeout(tryColoring, 100)
      else
        $scroller.css(BGColorPropName, color)
        $wrapper.parent().css(BGColorPropName, color)
    tryColoring()

  # Immediately overrides the setting of `overflow-x` to `scroll` (thus, not creating a horizontal scrollbar)
  $computeLayerConfig_ = editor.renderer.$computeLayerConfig
  editor.renderer.$computeLayerConfig = ->
    $computeLayerConfig_.apply(editor.renderer, arguments)
    $scroller.css("overflow-x", "hidden")
    $content.css("margin-top", "0px") # Avoids an annoying issue where Ace, without scrolling enabled,
                                      # toggles the top margin between 0px and -4px with each character inserted

  # Retain only the desired keybindings for the command center
  miscCmdNames =
    ['alignCursors', 'backspace', 'cut', 'del', 'delete', 'end', 'home', 'insert', 'insertstring', 'inserttext', 'left', 'overwrite', 'pagedown',
     'pageup', 'redo', 'removeline', 'right', 'undo']

  gotoCmdNames =
    ['gotoend', 'gotoleft', 'gotolineend', 'gotolinestart', 'gotopagedown', 'gotopageup', 'gotoright', 'gotostart', 'gotowordleft', 'gotowordright']

  removeCmdNames =
    ['removetolinestart', 'removetolineend', 'removewordleft', 'removewordright']

  selectCmdNames =
    ['selectall', 'selectdown', 'selectleft', 'selectlineend', 'selectlinestart', 'selectMoreAfter', 'selectMoreBefore', 'selectNextAfter',
     'selectNextBefore', 'selectpagedown', 'selectpageup', 'selectright', 'selecttoend', 'selecttolineend', 'selecttolinestart', 'selecttostart',
     'selectup', 'selectwordleft', 'selectwordright']

  cmdNames = [].concat(miscCmdNames, gotoCmdNames, removeCmdNames, selectCmdNames)
  cmdSet   = _(cmdNames).foldl(((acc, x) -> acc[x] = true; acc), {})

  commands = _(editor.commands.byName).filter((x) -> not cmdSet[x.name]).map((x) -> x.name)
  editor.commands.removeCommands(commands)

  # key: The key/command we're creating a listener for
  # f:   Function of what to do when the key(s) is/are pressed (expected args: `(env, args, request)`
  makeCommand = (key) -> (f) ->
    {
      name: key.toLowerCase(),
      bindKey: {
        win:    key.replace(/MCtrl-/i, "Ctrl-"), # This way, "MCtrl" => "Ctrl" for Windows and "Cmd" for Mac, and "Ctrl" => "Ctrl" for both
        mac:    key.replace(/MCtrl-/i, "Cmd-"),
        sender: id
      },
      exec: f
    }

  upCmd = makeCommand("Up") (
    ->
      UI.scrollMessageListUp()
      editor.selection.clearSelection()
  )

  downCmd = makeCommand("Down") (
    ->
      UI.scrollMessageListDown()
      editor.selection.clearSelection()
  )

  enterCmd  = makeCommand("Enter") (-> UI.sendInput())
  tabCmd    = makeCommand("Tab")   (-> UI.nextAgentType())
  ctrlLCmd  = makeCommand("Ctrl-L")(-> UI.clearChat())
  pageUpCmd = makeCommand("Pageup")(-> $globals.$container.focus())

  # Set up the Ctrl/Cmd+Shift+<Num> shortcuts...
  AgentTypeCount  = 5
  agentTypeNumArr = [1..AgentTypeCount]

  mctrlArr    = agentTypeNumArr[0..].map((x) -> "MCtrl-Shift-"+ x)
  mctrlCmdArr = _(mctrlArr).map((cmd) -> makeCommand(cmd)(-> UI.setAgentTypeIndex(_(cmd).last() - 1)))

  newCommands = [].concat(upCmd, downCmd, enterCmd, tabCmd, ctrlLCmd, pageUpCmd, mctrlCmdArr)
  editor.commands.addCommands(newCommands)

commandCenterInit()

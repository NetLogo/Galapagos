window.tortoise = (elt, socketURL) ->
  elt = elt or '.netlogo-model'
  if typeof elt == 'string'
    elt = document.querySelector elt
  if not socketURL?
    socketURL = elt.dataset.url

  srcURL = elt.dataset.src
  code = elt.textContent
  # Clearing textContent must happen before creating the session since
  # since blanking out textContent clears out child elements too.
  elt.textContent = ''

  session = createSession elt, socketURL

  if srcURL?
    session.openURL srcURL
  else if code.trim()
    editor.setValue code
    editor.clearSelection()
    editor.getSelection().moveCursorFileStart()

  session

createSession = (elt, socketURL) ->
  container = document.createElement 'div'
  container.classList.add 'view-container'
  elt.appendChild container
  elt.appendChild document.createElement 'div'

  editor = attachEditor elt

  controller = new AgentStreamController(container)
  connection = connect(socketURL)
  session = new TortoiseSession(connection, controller, editor)

  session

attachEditor = (elt) ->
  editorElt = document.createElement('div')
  editorElt.style.height = '200px'
  elt.appendChild editorElt
  editor = ace.edit editorElt
  editor.setTheme 'ace/theme/netlogo-classic'
  editor.getSession().setMode 'ace/mode/netlogo'
  editor.setFontSize '11px'
  editor.renderer.setShowGutter false
  editor.setShowPrintMargin false
  editor

class TortoiseSession
  constructor: (@connection, @controller, @editor) ->
    @connection.on 'update', (msg)       => @update(JSON.parse(msg.message))
    @connection.on 'js', (msg)           => @runJSCommand(msg.message)
    @connection.on 'model_update', (msg) => @evalJSModel(msg.message)

    # Start autocompile
    compileTimeout = -1
    @editor.session.on 'change', =>
      clearTimeout(compileTimeout)
      compileTimeout = setTimeout(=>
        console.log('recompiling')
        @recompile()
      , 500)


  update: (modelUpdate) ->
    if modelUpdate instanceof Array
      @controller.update(update) for update in modelUpdate
    else
      @controller.update(modelUpdate)
    @controller.repaint()

  evalJSModel: (js) ->
    eval.call(window, js)
    @update collectUpdates()

  runJSCommand: (js) ->
    (new Function(js)).call(window, js)
    @update collectUpdates()

  # TODO: Give this a callback parameter that gets called with the response
  run: (agentType, cmd) ->
    @connection.send {agentType: agentType, cmd: cmd}

  openURL: (nlogoURL) ->
    req = new XMLHttpRequest()
    req.onreadystatechange = =>
      if req.readyState == req.DONE
        nlogoContents = req.responseText
        @open nlogoContents
    req.open 'GET', nlogoURL
    req.send()

  open: (nlogoContents) ->
    @run 'open', nlogoContents
    if @editor?
      endOfCode = nlogoContents.indexOf '@#$#@#$#@'
      if endOfCode >= 0
        code = nlogoContents.substring 0, endOfCode
      @editor.setValue code
      @editor.clearSelection()

  recompile: () ->
    console.log 'recompiling'
    @run 'compile', @editor.getValue()

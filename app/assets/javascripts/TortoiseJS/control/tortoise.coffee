window.tortoise = (elem, socketURL) ->
  elem = elem or '.netlogo-model'
  if typeof elem == 'string'
    elem = document.querySelector(elem)
  if not socketURL?
    socketURL = elem.dataset.url

  srcURL = elem.dataset.src
  code = elem.textContent
  # Clearing textContent must happen before creating the session since
  # since blanking out textContent clears out child elements too.
  elem.textContent = ''

  session = createSession(elem, socketURL)

  if srcURL?
    session.openURL(srcURL)
  else if code.trim()
    editor.setValue(code)
    editor.clearSelection()
    editor.getSelection().moveCursorFileStart()

  session

createSession = (elem, socketURL) ->
  container = document.createElement('div')
  container.classList.add('view-container')
  elem.appendChild(container)
  elem.appendChild(document.createElement 'div')

  editor = attachEditor(elem)

  controller = new AgentStreamController(container)
  connection = connect(socketURL)
  session = new TortoiseSession(connection, controller, editor)

  session

attachEditor = (elem) ->
  editorElem = document.createElement('div')
  editorElem.style.height = '200px'
  elem.appendChild(editorElem)
  editor = ace.edit(editorElem)
  editor.setTheme('ace/theme/netlogo-classic')
  editor.getSession().setMode('ace/mode/netlogo')
  editor.setFontSize('11px')
  editor.renderer.setShowGutter(false)
  editor.setShowPrintMargin(false)
  editor

class TortoiseSession
  constructor: (@connection, @controller, @editor) ->
    @connection.on('update',       (msg) => @update(JSON.parse(msg.message)))
    @connection.on('js',           (msg) => @runJSCommand(msg.message))
    @connection.on('model_update', (msg) => @evalJSModel(msg.message))

    # Start autocompile
    compileTimeout = -1
    @editor.session.on('change', =>
      clearTimeout(compileTimeout)
      compileTimeout = setTimeout((=> @recompile()), 500))
    @run('compile', '') # initialize as blank model.


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

  run: (agentType, cmd) ->
    @connection.send({agentType: agentType, cmd: cmd})

  openURL: (nlogoURL) ->
    ajax(nlogoURL, (nlogoContents) => @open(nlogoContents))

  open: (nlogoContents) ->
    @run('open', nlogoContents)
    if @editor?
      endOfCode = nlogoContents.indexOf('@#$#@#$#@')
      if endOfCode >= 0
        code = nlogoContents.substring(0, endOfCode)
      @editor.setValue(code)
      @editor.clearSelection()

  recompile: () ->
    console.log('Sending recompile request')
    @run('compile', @editor.getValue())

ajax = (url, callback) ->
  req = new XMLHttpRequest()
  req.onreadystatechange = ->
    if req.readyState == req.DONE
      callback(req.responseText)
  req.open('GET', url)
  req.send()


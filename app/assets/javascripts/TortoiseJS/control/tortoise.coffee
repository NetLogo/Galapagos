window.initTortoise = (socketURL, elements) ->
  ###
  socketURL - This socketURL will be used if an element doesn't define a
    data-url
  elements  - Either a list of elements or query selector.
    Defaults to '.netlogo-model'
  ###
  tortoise =
    socketURL: socketURL
    sessions: []
    initSession: (container, socketURL) ->
      socketURL = socketURL or tortoise.socketURL
      controller = new AgentStreamController(container)
      connection = connect(socketURL)
      session = new TortoiseSession(connection, controller)
      tortoise.sessions.push(session)
      session

    attachEditor: (container, session) ->
      editorElt = document.createElement('div')
      editorElt.style.height = '200px'
      container.appendChild(editorElt)
      editor = ace.edit(editorElt)
      editor.setTheme('ace/theme/netlogo-classic')
      editor.getSession().setMode('ace/mode/netlogo')
      editor.setFontSize('14px')
      editor.renderer.setShowGutter(false);
      editor.setShowPrintMargin(false)
      container.appendChild(editorElt)
      compileTimeout = -1
      editor.session.on 'change', ->
        clearTimeout(compileTimeout)
        compileTimeout = setTimeout(->
          console.log "recompiling"
          session.run('compile', editor.getValue())
        , 500)
      editor

    init: (element) ->
      socketURL = element.dataset.url or tortoise.socketURL
      srcURL = element.dataset.src
      code = element.textContent
      element.textContent = ''

      container = document.createElement('div')
      container.classList.add('view-container')
      element.appendChild(container)

      session = tortoise.initSession(container, socketURL)
      editor = tortoise.attachEditor(element, session)

      if srcURL?
        console.log srcURL
        req = new XMLHttpRequest()
        req.onreadystatechange = ->
          if req.readyState == req.DONE
            nlogoContents = req.responseText
            endOfCode = nlogoContents.indexOf '@#$#@#$#@'
            if endOfCode >= 0
              code = nlogoContents.substring(0, endOfCode)
            editor.setValue(code)
            editor.clearSelection()
            session.run('open', nlogoContents)
            console.log "loaded"
        req.open('GET', '/assets/models/Autumn.nlogo', true)
        req.send()
      else if code.trim()
        editor.setValue(code)
        editor.clearSelection()
      session
  elements = elements or '.netlogo-model'
  if typeof elements == 'string'
    elements = document.querySelectorAll(elements)
  for element in elements
    tortoise.init(element)
  tortoise

class TortoiseSession
  constructor: (@connection, @controller) ->
    @connection.on 'update', (msg)       => @update(JSON.parse(msg.message))
    @connection.on 'js', (msg)           => @runJSCommand(msg.message)
    @connection.on 'model_update', (msg) => @evalJSModel(msg.message)

  update: (modelUpdate) ->
    if modelUpdate instanceof Array
      @controller.update(update) for update in modelUpdate
    else
      @controller.update(modelUpdate)
    @controller.repaint()

  evalJSModel: (js) ->
    eval.call(window, js)
    @update(collectUpdates())

  runJSCommand: (js) ->
    (new Function(js)).call(window, js)
    @update(collectUpdates())

  # TODO: Give this a callback parameter that gets called with the response
  run: (agentType, cmd) ->
    @connection.send({agentType: agentType, cmd: cmd})

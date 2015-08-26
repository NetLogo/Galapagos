DEFAULT_UPDATE_DELAY = 1000 / 60
MAX_UPDATE_DELAY     = 1000
FAST_UPDATE_EXP      = 0.5
SLOW_UPDATE_EXP      = 4
MAX_UPDATE_TIME      = 100

DEFAULT_REDRAW_DELAY = 1000 / 30
MAX_REDRAW_DELAY     = 1000
REDRAW_EXP           = 2

class window.SessionLite
  constructor: (@widgetController) ->
    @_eventLoopTimeout = -1
    @_lastRedraw = 0
    @_lastUpdate = 0
    @widgetController.ractive.on('editor.recompile',   (event) => @recompile())
    @widgetController.ractive.on('exportnlogo',        (event) => @exportnlogo(event))
    @widgetController.ractive.on('exportHtml',         (event) => @exportHtml(event))
    @widgetController.ractive.on('console.run',        (code)  => @run(code))
    @drawEveryFrame = false

  modelTitle: ->
    @widgetController.ractive.get('modelTitle')

  startLoop: ->
    if procedures.startup? then procedures.startup()
    @widgetController.redraw()
    @widgetController.updateWidgets()
    requestAnimationFrame(@eventLoop)

  updateDelay: ->
    speed = @widgetController.speed()
    if speed > 0
      speedFactor = Math.pow(Math.abs(speed), FAST_UPDATE_EXP)
      DEFAULT_UPDATE_DELAY * (1 - speedFactor)
    else
      speedFactor = Math.pow(Math.abs(speed), SLOW_UPDATE_EXP)
      MAX_UPDATE_DELAY * speedFactor + DEFAULT_UPDATE_DELAY * (1 - speedFactor)

  redrawDelay: ->
    speed       = @widgetController.speed()
    if speed > 0
      speedFactor = Math.pow(Math.abs(@widgetController.speed()), REDRAW_EXP)
      MAX_REDRAW_DELAY * speedFactor + DEFAULT_REDRAW_DELAY * (1 - speedFactor)
    else
      DEFAULT_REDRAW_DELAY

  eventLoop: (timestamp) =>
    @_eventLoopTimeout = requestAnimationFrame(@eventLoop)
    updatesDeadline = Math.min(@_lastRedraw + @redrawDelay(), now() + MAX_UPDATE_TIME)
    maxNumUpdates   = if @drawEveryFrame then 1 else (now() - @_lastUpdate) / @updateDelay()

    for i in [1..maxNumUpdates] by 1 # maxNumUpdates can be 0. Need to guarantee i is ascending.
      @_lastUpdate = now()
      @widgetController.runForevers()
      if now() >= updatesDeadline
        break

    if Updater.hasUpdates()
      # First conditional checks if we're on time with updates. If so, we may as
      # well redraw. This keeps animations smooth for fast models. BCH 11/4/2014
      if i > maxNumUpdates or now() - @_lastRedraw > @redrawDelay() or @drawEveryFrame
        @_lastRedraw = now()
        @widgetController.redraw()
      @widgetController.updateWidgets()

  teardown: ->
    @widgetController.teardown()
    cancelAnimationFrame(@_eventLoopTimeout)

  recompile: ->
    # This is a temporary workaround for the fact that models can't be reloaded
    # without clearing the world. BCH 1/9/2015
    Tortoise.startLoading( =>
      world.clearAll()
      @widgetController.redraw()
      codeCompile(@widgetController.code(), [], [], @widgetController.widgets, (res) ->
        if res.model.success
          globalEval(res.model.result)
        else
          alert(res.model.result.map((err) -> err.message).join('\n'))
        Tortoise.finishLoading()
      )
    )

  getNlogo: ->
    (new BrowserCompiler()).exportNlogo({
      info:         @widgetController.ractive.get('info'),
      code:         @widgetController.ractive.get('code'),
      widgets:      @widgetController.widgets,
      turtleShapes: turtleShapes,
      linkShapes:   linkShapes
    })

  exportnlogo: ->
    exportName = @promptFilename(".nlogo")
    if exportName?
      exportedNLogo = @getNlogo()
      if (exportedNLogo.success)
        exportBlob = new Blob([exportedNLogo.result], {type: "text/plain:charset=utf-8"})
        saveAs(exportBlob, exportName)
      else
        alert(exportedNLogo.result.map((err) -> err.message).join('\n'))

  promptFilename: (extension) ->
    suggestion = @modelTitle() + extension
    window.prompt('Filename:', suggestion)


  exportHtml: ->
    exportName = @promptFilename(".html")
    if exportName?
      window.req = new XMLHttpRequest()
      req.open('GET', standaloneURL)
      req.onreadystatechange = =>
        if req.readyState == req.DONE
          if req.status is 200
            nlogo = @getNlogo()
            if nlogo.success
              parser = new DOMParser()
              dom = parser.parseFromString(req.responseText, "text/html")
              nlogoScript = dom.querySelector("#nlogo-code")
              nlogoScript.textContent = nlogo.result
              nlogoScript.dataset.filename = exportName.replace(/\.html$/, ".nlogo")
              wrapper = document.createElement("div")
              wrapper.appendChild(dom.documentElement)
              exportBlob = new Blob([wrapper.innerHTML], {type: "text/html:charset=utf-8"})
              saveAs(exportBlob, exportName)
            else
              alert(nlogo.result.map((err) -> err.message).join("\n"))
          else
            alert("Couldn't get standalone page")
      req.send("")

  makeForm:(method, path, data) ->
    form = document.createElement('form')
    form.setAttribute('method', method)
    form.setAttribute('action', path)
    for name, value of data
      field = document.createElement('input')
      field.setAttribute('type', 'hidden')
      field.setAttribute('name', name)
      field.setAttribute('value', value)
      form.appendChild(field)
    form


  run: (code) ->
    Tortoise.startLoading()
    codeCompile(@widgetController.code(), [code], [], @widgetController.widgets,
      (res) ->
        success = res.commands[0].success
        result  = res.commands[0].result
        Tortoise.finishLoading()
        if (success)
          new Function(result)()
        else
          alert(result.map((err) -> err.message).join('\n')))

window.Tortoise = {

  loadError: (url) ->
    """
      <div style='padding: 5px 10px;'>
        Unable to load NetLogo model from #{url}, please ensure:
        <ul>
          <li>That you can download the resource <a target="_blank" href="#{url}">at this link</a></li>
          <li>That the server containing the resource has
            <a target="_blank" href="https://en.wikipedia.org/wiki/Cross-origin_resource_sharing">
              Cross-Origin Resource Sharing
            </a>
            configured appropriately</li>
        </ul>
        If you have followed the above steps and are still seeing this error,
        please send an email to our <a href="mailto:bugs@ccl.northwestern.edu">"bugs" mailing list</a>
        with the following information:
        <ul>
          <li>The full URL of this page (copy and paste from address bar)</li>
          <li>Your operating system and browser version</li>
        </ul>
      </div>
    """

  # process: optional argument that allows the loading process to be async to
  # give the animation time to come up.
  startLoading: (process) ->
    document.querySelector("#loading-overlay").style.display = ""
    # This gives the loading animation time to come up. BCH 7/25/2015
    if (process?) then setTimeout(process, 20)

  finishLoading: ->
    document.querySelector("#loading-overlay").style.display = "none"

  # We separate on both / and \ because we get URLs and Windows-esque filepaths
  normalizedFileName: (path) ->
    pathComponents = path.split(/\/|\\/)
    decodeURI(pathComponents[pathComponents.length - 1])

  fromNlogo:         (nlogo, container, path, callback) ->
    nlogoCompile(nlogo, [], [], [], @browserCompileCallback(container, callback, @normalizedFileName(path)))

  fromURL:           (url,   container, callback) ->
    @startLoading()
    req = new XMLHttpRequest()
    req.open('GET', url)
    req.onreadystatechange = =>
      if req.readyState == req.DONE
        if (req.status == 0 || req.status >= 400)
          container.innerHTML = @loadError(url)
          @finishLoading()
        else
          nlogoCompile(req.responseText, [], [], [],
            @browserCompileCallback(container, callback, @normalizedFileName(url)))
    req.send("")

  fromCompiledModel: (container,
                      widgetString,
                      code,
                      info,
                      compiledSource = "",
                      readOnly = false,
                      filename = "export") ->
    widgets = globalEval(widgetString)
    widgetController = bindWidgets(container, widgets, code, info, readOnly, filename)
    window.modelConfig ?= {}
    modelConfig.plotOps = widgetController.plotOps
    modelConfig.mouse = widgetController.mouse
    modelConfig.print = { write: widgetController.write }
    modelConfig.output = widgetController.output
    globalEval(compiledSource)
    new SessionLite(widgetController)

  browserCompileCallback: (container, onSuccess, filename) ->
    (res) =>
      if res.model.success
        onSuccess(@fromCompiledModel(container, res.widgets, res.code,
          res.info, res.model.result, false, filename))
      else
        errors = res.model.result.map((err) -> err.message).join('<br/>')
        container.innerHTML = "<div style='padding: 5px 10px;'>#{errors}</div>"
      @finishLoading()
}

window.AgentModel = tortoise_require('agentmodel')

window.nlogoCompile = (model, commands, reporters, widgets, onFulfilled) ->
  onFulfilled((new BrowserCompiler()).fromNlogo(model, commands))

window.codeCompile = (code, commands, reporters, widgets, onFulfilled) ->
  compileParams = {
    code:         code,
    widgets:      widgets,
    commands:     commands,
    reporters:    reporters,
    turtleShapes: turtleShapes ? [],
    linkShapes:   linkShapes ? []
  }
  onFulfilled((new BrowserCompiler()).fromModel(compileParams))

window.serverNlogoCompile = (model, commands, reporters, widgets, onFulfilled) ->
  compileParams = {
    model:     model,
    commands:  JSON.stringify(commands),
    reporters: JSON.stringify(reporters)
  }
  compileCallback = (res) ->
    onFulfilled(JSON.parse(res))
  ajax('/compile-nlogo', compileParams, compileCallback)

window.serverCodeCompile = (code, commands, reporters, widgets, onFulfilled) ->
  compileParams = {
    code,
    widgets:      JSON.stringify(widgets),
    commands:     JSON.stringify(commands),
    reporters:    JSON.stringify(reporters),
    turtleShapes: JSON.stringify(turtleShapes ? []),
    linkShapes:   JSON.stringify(linkShapes ? [])
  }
  compileCallback = (res) ->
    onFulfilled(JSON.parse(res))
  ajax('/compile-code', compileParams, compileCallback)

window.ajax = (url, params, callback) ->
  paramPairs = for key, value of params
    encodeURIComponent(key) + '=' + encodeURIComponent(value)
  req = new XMLHttpRequest()
  req.open('POST', url)
  req.onreadystatechange = ->
    if req.readyState == req.DONE
      callback(req.responseText)
  req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
  req.send(paramPairs.join('&'))

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

# performance.now gives submillisecond timing, which improves the event loop
# for models with submillisecond go procedures. Unfortunately, iOS Safari
# doesn't support it. BCH 10/3/2014
now = performance?.now.bind(performance) ? Date.now.bind(Date)

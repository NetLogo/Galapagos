teletortoise = (element) ->
  container = document.createElement('div')
  container.classList.add('view-container')

  code = element.textContent
  element.textContent = ''

  element.appendChild(container)
  window.controller = new AgentStreamController(container)

  editorElt = document.createElement("div")
  editorElt.style.height = "200px"
  element.appendChild(editorElt)
  editor = ace.edit(editorElt)
  editor.setTheme("ace/theme/netlogo-classic")
  editor.getSession().setMode("ace/mode/netlogo")
  editor.setFontSize("14px")
  editor.renderer.setShowGutter(false);
  editor.setShowPrintMargin(false)
  exports.NLEditor = editor
  exports.initChat()

  compileTimeout = -1
  editor.session.on('change', ->
    clearTimeout(compileTimeout)
    compileTimeout = setTimeout( ->
      exports.ChatServices.UI.run('compile', editor.getValue())
    , 500)
  )
  if code.trim()
    console.log('inline')
    editor.setValue(code)
    editor.clearSelection()

window.addEventListener('load', ->
  for elt in document.getElementsByClassName('netlogo-model')
    teletortoise(elt)
)
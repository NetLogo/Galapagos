teletortoise = (element) ->
  container = document.createElement('div')
  container.classList.add('view-container')

  element.appendChild(container)
  window.controller = new AgentStreamController(container)

  editorElt = document.createElement("div")
  editorElt.style.height = "200px"
  element.appendChild(editorElt)
  editor = ace.edit(editorElt)
  editor.setTheme("ace/theme/netlogo-classic")
  editor.getSession().setMode("ace/mode/netlogo")
  editor.setFontSize("14px")
  editor.setShowPrintMargin(false)
  exports.NLEditor = editor
  exports.initChat()

  console.log('bar')
  compileTimeout = -1
  editor.session.on('change', ->
    clearTimeout(compileTimeout)
    compileTimeout = setTimeout( ->
      exports.ChatServices.UI.run('compile', editor.getValue())
    , 500)
  )

window.addEventListener('load', ->
  for elt in document.getElementsByClassName('netlogo-model')
    teletortoise(elt)
)
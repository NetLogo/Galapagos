TRACE_EVENTS = ['pointerdown', 'pointerup', 'pointercancel', 'contextmenu', 'touchend', 'touchcancel', 'click']
MAX_LINES    = 12

isInstalled = false

# () => Unit
installTouchTrace = ->

  if isInstalled
    return

  isInstalled = true
  panel       = document.createElement('pre')
  Object.assign(panel.style, {
    position:      'fixed'
  , top:           '0'
  , left:          '0'
  , zIndex:        '10000'
  , margin:        '0'
  , padding:       '4px'
  , font:          '20px monospace'
  , background:    'rgba(255, 255, 200, 0.9)'
  , cursor:        'pointer'
  })
  document.body.appendChild(panel)

  # `navigator.clipboard` needs a secure context, and the dev server is plain HTTP.
  panel.addEventListener('click', ->
    text = panel.textContent
    area = document.createElement('textarea')
    area.value = text
    area.setAttribute('readonly', '')
    document.body.appendChild(area)
    area.select()
    document.execCommand('copy')
    area.remove()
    panel.textContent = "#{text}\n(copied)"
    return
  )

  lines     = []
  startTime = performance.now()

  TRACE_EVENTS.forEach((type) ->
    document.addEventListener(type, ((e) ->
      if panel.contains(e.target)
        return
      if type is 'pointerdown' and e.isPrimary
        startTime = performance.now()
        lines     = []
      ms     = Math.round(performance.now() - startTime)
      source = if e.isTrusted then 'native' else 'ours'
      lines.push("#{ms} #{type} #{e.pointerType ? ''} #{source} #{e.target.classList?[0] ? e.target.nodeName}")
      panel.textContent = lines.slice(-MAX_LINES).join('\n')
      return
    ), true)
  )

  return

export default installTouchTrace

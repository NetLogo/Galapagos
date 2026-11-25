MAX_PRESSES  = 8
MAX_TEXT     = 40

isOn         = false
state        = undefined
openPointers = new Map()

# (String) => String
clip = (text) ->
  flat = text.replace(/\s+/g, ' ').trim()
  if flat.length > MAX_TEXT then "#{flat.slice(0, MAX_TEXT)}…" else flat

# (Number) => String
round = (n) ->
  if Math.abs(n - Math.round(n)) < 0.05 then "#{Math.round(n)}" else n.toFixed(1)

# (Element) => String
describeElement = (el) ->
  id      = if el.id then "##{el.id}" else ''
  classes = Array.from(el.classList ? []).slice(0, 3).map((c) -> ".#{c}").join('')
  "#{el.tagName?.toLowerCase() ? '?'}#{id}#{classes}"

# (EventTarget) => String
describeTarget = (target) ->
  if not (target instanceof Element)
    return if target is window then 'window' else if target is document then 'document' else ''
  chain = []
  el    = target
  while el? and (el isnt document.body) and (chain.length < 4)
    if el.classList.contains('netlogo-widget-container')
      break
    if el.classList.contains('netlogo-widget')
      chain.push("#{el.tagName.toLowerCase()}##{el.id}")
      break
    chain.push(describeElement(el))
    el = el.parentElement
  widget =
    try
      window.Ractive?.getContext(target)?.ractive?.get('widget')
    catch
      undefined
  suffix = if widget?.type? then " {#{widget.type} #{widget.id}}" else ''
  "#{chain.join(' < ')}#{suffix}"

# (Event) => Boolean
isInPanel = (e) ->
  e.target instanceof Node and state.panel.contains(e.target)

# () => String
header = ->
  media = (q) -> if window.matchMedia(q).matches then 'yes' else 'no'
  [
    "NetLogo Web trace #{new Date().toISOString()}"
  , "URL: #{window.location.href}"
  , "In iframe: #{window isnt window.parent}"
  , "UA: #{navigator.userAgent}"
  , "pointer fine/coarse/none: #{media('(pointer: fine)')}/#{media('(pointer: coarse)')}/#{media('(pointer: none)')}" +
    ", any-pointer coarse: #{media('(any-pointer: coarse)')}" +
    ", hover: #{media('(hover: hover)')}, any-hover: #{media('(any-hover: hover)')}"
  , "nlw-phone: #{document.documentElement.classList.contains('nlw-phone')}"
  , "screen: #{screen.width}x#{screen.height}, dpr: #{window.devicePixelRatio}" +
    ", window: #{window.innerWidth}x#{window.innerHeight}, maxTouchPoints: #{navigator.maxTouchPoints}"
  ].join('\n')

# () => Press
newPress = (label) ->
  press = {
    label
  , startTime: performance.now()
  , clock:     new Date().toTimeString().slice(0, 8)
  , lines:     []
  , moves:     0
  , maxDist:   0
  , pendingMoves: 0
  , origin:    undefined
  , isDown:    false
  , pointerType: ''
  , target:    ''
  , element:   undefined
  }
  press

# (Press) => String
pressSummary = (press) ->
  moves  = if press.moves > 0 then " · #{press.moves} moves, max #{round(press.maxDist)}px" else ''
  target = if press.target then " · #{press.target}" else ''
  "#{press.label} #{press.clock} #{press.pointerType}#{moves}#{target}"

# (Press) => Unit
renderPress = (press) ->
  if not press.element?
    group   = document.createElement('div')
    summary = document.createElement('div')
    summary.className = 'nlw-trace-press'
    body    = document.createElement('div')
    group.append(summary, body)
    state.list.append(group)
    press.element = { group, summary, body, rendered: 0 }
  { summary, body } = press.element
  summary.textContent = pressSummary(press)
  while press.element.rendered < press.lines.length
    line = document.createElement('div')
    line.className = 'nlw-trace-line'
    body.append(line)
    press.element.rendered += 1
  Array.from(body.children).forEach((div, i) -> div.textContent = press.lines[i].text(); return)
  return

# () => Unit
scheduleRender = ->
  if not state.renderId?
    state.renderId = window.setTimeout(->
      state.renderId = undefined
      state.presses.forEach(renderPress)
      state.list.scrollTop = state.list.scrollHeight
      return
    , 0)
  return

# (() => String, String?) => Line
addLine = (text, foldKey) ->
  press = state.presses[state.presses.length - 1]
  if press.pendingMoves > 0
    moves = press.pendingMoves
    dist  = press.maxDist
    press.pendingMoves = 0
    press.lines.push({ text: -> "        … #{moves} pointermove, max #{round(dist)}px from start" })
  last = press.lines[press.lines.length - 1]
  if foldKey? and last?.foldKey is foldKey
    last.repeats += 1
    last.base = text
    last
  else
    line = { foldKey, repeats: 1, base: text, text: -> if @repeats > 1 then "#{@base()} ×#{@repeats}" else @base() }
    press.lines.push(line)
    scheduleRender()
    line

# () => String
elapsed = ->
  press = state.presses[state.presses.length - 1]
  "+#{Math.round(performance.now() - press.startTime)}".padStart(6)

# (String) => Unit
startPress = (pointerType, target) ->
  state.pressNumber += 1
  press = newPress("##{state.pressNumber}")
  press.pointerType = pointerType
  press.target      = target
  state.presses.push(press)
  while state.presses.length > MAX_PRESSES
    dropped = state.presses.shift()
    dropped.element?.group.remove()
  return

# (Event) => String
pointerFields = (e) ->
  parts = []
  if e.pointerType?
    parts.push("#{e.pointerType} id#{e.pointerId}#{if e.isPrimary then ' prim' else ''}")
  if e.button?
    parts.push("b#{e.button}/#{e.buttons}")
  if e.detail? and (e.detail isnt 0)
    parts.push("detail=#{e.detail}")
  if e.clientX?
    parts.push("@#{round(e.clientX)},#{round(e.clientY)}")
  if e.isLongPress
    parts.push('ours')
  parts.join(' ')

# () => String
activation = ->
  ua = navigator.userActivation
  if not ua?
    'act=n/a'
  else if ua.isActive
    'act=ACTIVE'
  else if ua.hasBeenActive
    'act=sticky'
  else
    'act=none'

# (Event, String) => Unit
logEvent = (e, fields) ->
  target = describeTarget(e.target)
  time   = elapsed()
  press  = state.presses[state.presses.length - 1]
  shown  = if target is press.target then '' else " → #{target}"
  head   = [e.type, fields, activation()].filter((part) -> part).join(' ')
  line   = addLine(-> "#{time} #{head}")
  window.setTimeout(->
    flags = []
    if e.defaultPrevented then flags.push('PREVENTED')
    if not e.isTrusted    then flags.push('untrusted')
    flagText = if flags.length > 0 then " [#{flags.join(', ')}]" else ''
    line.base = -> "#{time} #{head}#{flagText}#{shown}"
    scheduleRender()
    return
  , 0)
  return

# () => String
describeOpenPointers = ->
  now  = performance.now()
  open = Array.from(openPointers, ([id, { type, time }]) -> "id#{id} #{type} #{Math.round(now - time)}ms")
  "NON-PRIMARY, still down: #{if open.length > 0 then open.join(', ') else 'none seen'}"

# (PointerEvent) => Unit
handlePointer = (e) ->
  if e.type is 'pointerdown'
    nonPrimary = if e.isPrimary then '' else describeOpenPointers()
    openPointers.set(e.pointerId, { type: e.pointerType, time: performance.now() })
  else if ['pointerup', 'pointercancel'].includes(e.type)
    openPointers.delete(e.pointerId)
  if isInPanel(e)
    return
  current = state.presses[state.presses.length - 1]
  if e.type is 'pointerdown' and e.isPrimary
    startPress(e.pointerType, describeTarget(e.target))
    press        = state.presses[state.presses.length - 1]
    press.origin = { x: e.clientX, y: e.clientY, id: e.pointerId }
    press.isDown = true
  else if ['pointerup', 'pointercancel'].includes(e.type) and (e.pointerId is current.origin?.id)
    current.isDown = false
  logEvent(e, [pointerFields(e), nonPrimary].filter((part) -> part).join(' '))
  return

# (PointerEvent) => Unit
handlePointerMove = (e) ->
  press = state.presses[state.presses.length - 1]
  if press.isDown and (e.pointerId is press.origin.id)
    press.moves        += 1
    press.pendingMoves += 1
    press.maxDist       = Math.max(press.maxDist, Math.hypot(e.clientX - press.origin.x, e.clientY - press.origin.y))
    scheduleRender()
  return

# (TouchEvent) => Unit
handleTouch = (e) ->
  if not isInPanel(e)
    logEvent(e, "touches=#{e.touches.length} changed=#{e.changedTouches.length}")
  return

# (MouseEvent) => Unit
handleMouse = (e) ->
  if not isInPanel(e)
    logEvent(e, pointerFields(e))
  return

# (Event) => Unit
handleSelectStart = (e) ->
  if not isInPanel(e)
    logEvent(e, '')
  return

# () => Unit
handleSelectionChange = ->
  selection = window.getSelection()
  text      = clip(selection?.toString() ? '')
  anchor    = selection?.anchorNode
  if (text isnt state.lastSelection) and not (anchor? and state.panel.contains(anchor))
    state.lastSelection = text
    time = elapsed()
    addLine(-> "#{time} selectionchange \"#{text}\"")
  return

# (FocusEvent) => Unit
handleFocus = (e) ->
  if not isInPanel(e)
    logEvent(e, '')
  return

# (ClipboardEvent) => Unit
handleCopy = (e) ->
  if not isInPanel(e)
    logEvent(e, "\"#{clip(window.getSelection()?.toString() ? '')}\"")
  return

# (Event) => Unit
handleViewport = (e) ->
  vv   = e.target
  time = elapsed()
  text = "scale=#{round(vv.scale)} offset=#{round(vv.offsetLeft)},#{round(vv.offsetTop)} " +
         "page=#{round(vv.pageLeft)},#{round(vv.pageTop)} size=#{round(vv.width)}x#{round(vv.height)}"
  addLine((-> "#{time} viewport #{e.type} #{text}"), "viewport-#{e.type}")
  scheduleRender()
  return

# () => String
textForCopy = ->
  presses = state.presses.map((press) ->
    [pressSummary(press)].concat(press.lines.map((line) -> line.text())).join('\n')
  )
  [header(), ''].concat(presses).join('\n\n')

# (String) => Promise[String]
copyText = (text) ->
  try
    await navigator.clipboard.writeText(text)
    'Copied'
  catch error
    area = document.createElement('textarea')
    area.value = text
    area.setAttribute('readonly', '')
    area.style.position = 'fixed'
    area.style.top      = '0'
    area.style.opacity  = '0'
    state.panel.append(area)
    area.focus()
    area.setSelectionRange(0, text.length)
    isCopied = document.execCommand('copy')
    area.remove()
    if isCopied then 'Copied (fallback)' else "Copy failed: #{error?.message ? error}"

STYLE =
  """
  .nlw-trace-wrap { padding: 8px 12px 16px; }
  .nlw-trace { font: 11px/1.3 ui-monospace, Menlo, Consolas, monospace; color: #111;
    background: #fffff0; border: 1px solid #888; border-radius: 4px; touch-action: manipulation; }
  .nlw-trace > button { display: block; font: inherit; padding: 4px 12px; margin: 3px; }
  .nlw-trace-list { max-height: 400px; overflow: auto; -webkit-user-select: text; user-select: text;
    border-top: 1px solid #ccc; }
  .nlw-trace-press { padding: 2px 4px; background: #eee; border-top: 1px solid #ddd; font-weight: bold;
    white-space: pre-wrap; word-break: break-all; }
  .nlw-trace-line { padding: 0 4px; white-space: pre-wrap; word-break: break-all; }
  .nlw-trace-line:nth-child(even) { background: rgba(0, 0, 0, 0.04); }
  """

# () => Unit
buildPanel = ->
  style = document.createElement('style')
  style.textContent = STYLE
  document.head.append(style)

  panel = document.createElement('div')
  panel.className = 'nlw-trace-wrap'
  box   = document.createElement('div')
  box.className = 'nlw-trace'
  list  = document.createElement('div')
  list.className = 'nlw-trace-list'
  copy  = document.createElement('button')
  copy.type        = 'button'
  copy.textContent = 'Copy'
  copy.addEventListener('click', ->
    copy.textContent = await copyText(textForCopy())
    window.setTimeout((-> copy.textContent = 'Copy'; return), 2000)
    return
  )
  box.append(copy, list)
  panel.append(box)
  for type in ['pointerdown', 'pointerup', 'mousedown', 'mouseup', 'click', 'contextmenu', 'touchstart', 'touchend']
    panel.addEventListener(type, (e) -> e.stopPropagation(); return)

  Object.assign(state, { panel, list })
  return

# () => Unit
installListeners = ->
  listen = (target, type, handler, options = { capture: true, passive: true }) ->
    target.addEventListener(type, handler, options)
    return

  for type in ['pointerdown', 'pointerup', 'pointercancel', 'gotpointercapture', 'lostpointercapture']
    listen(window, type, handlePointer)
  listen(window, 'pointermove', handlePointerMove)
  for type in ['touchstart', 'touchend', 'touchcancel']
    listen(window, type, handleTouch)
  for type in ['contextmenu', 'click', 'dblclick']
    listen(window, type, handleMouse)
  listen(window, 'selectstart', handleSelectStart)
  listen(document, 'selectionchange', handleSelectionChange)
  listen(window, 'focusin', handleFocus)
  listen(window, 'focusout', handleFocus)
  listen(window, 'copy', handleCopy)

  viewport = window.visualViewport
  try
    top = window.top
    if top.visualViewport? and top.document?
      viewport = top.visualViewport
  catch
  if viewport?
    listen(viewport, 'resize', handleViewport, undefined)
    listen(viewport, 'scroll', handleViewport, undefined)

  return

# Installs only when asked for by `?trace`.  Its listeners go on `window` in the capture phase, so call this before
# anything else registers handlers that might stop events. -Jeremy B November 2026
# () => Unit
installTracePanel = ->
  if isOn or not new URLSearchParams(window.location.search).has('trace')
    return
  isOn  = true
  state = {
    presses:       [newPress('Before first press')]
    pressNumber:   0
    lastSelection: ''
    renderId:      undefined
  }
  installListeners()
  buildPanel()
  scheduleRender()
  return

# The model is rebuilt on every load, so the panel is put back after it each time.  It goes outside the tab area,
# whose last tab inserts its content at the end of that area when opened. -Jeremy B November 2026
# (Element) => Unit
attachTracePanel = (container) ->
  if isOn
    container.append(state.panel)
  return

# (String, String) => Unit
trace = (category, message) ->
  if isOn
    time = elapsed()
    addLine(-> "#{time} [#{category}] #{message}")
  return

export { activation, attachTracePanel, installTracePanel, trace }

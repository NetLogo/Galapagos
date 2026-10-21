# (Element) => Unit
updateTooltip = (widget) ->
  label = widget.querySelector('.netlogo-label')
  if label? and label.scrollWidth > label.clientWidth
    widget.title = label.textContent.trim()
  else
    widget.removeAttribute('title')
  return

# (Element) => Unit
handleWidgetTooltips = (container) ->
  container.addEventListener('pointerover', (e) ->
    widget = e.target.closest('.netlogo-widget')
    if widget?
      updateTooltip(widget)
    return
  )
  return

export default handleWidgetTooltips

import { deviceWidth } from "/viewport-fit.js"

# Pinch-zoom belongs to the top window, so inside an iframe (the model on `/launch`) our own `visualViewport` does not
# see it.  Walk up to the top window, adding up each frame's position, so its visual viewport can be mapped back into
# this document's page coordinates.  A cross-origin parent stops the walk.
# () => { win: Window, x: Number, y: Number } | null
findTopWindow = ->
  win = window
  x   = 0
  y   = 0
  while win isnt win.parent
    frame = win.frameElement
    if not frame?
      return null
    parentWin = win.parent
    rect      = frame.getBoundingClientRect()
    x        += rect.left + frame.clientLeft + parentWin.scrollX - win.scrollX
    y        += rect.top  + frame.clientTop  + parentWin.scrollY - win.scrollY
    win       = parentWin
  { win, x, y }

# () => VisibleArea { left, top, right, bottom, width, height, scale: Number } | null
getVisibleArea = ->
  if not document.documentElement.classList.contains('nlw-phone')
    return null
  topWindow = findTopWindow()
  viewport  = topWindow?.win.visualViewport
  if not viewport?
    return null
  left   = Math.max(viewport.pageLeft - topWindow.x, window.scrollX)
  top    = Math.max(viewport.pageTop  - topWindow.y, window.scrollY)
  right  = Math.min(viewport.pageLeft - topWindow.x + viewport.width,  window.scrollX + window.innerWidth)
  bottom = Math.min(viewport.pageTop  - topWindow.y + viewport.height, window.scrollY + window.innerHeight)
  {
    left
  , top
  , right
  , bottom
  , width:  right  - left
  , height: bottom - top
  , scale:  Math.max(1, viewport.width / deviceWidth(topWindow.win))
  }

# (() => Unit) => (() => Unit)
watchVisibleArea = (callback) ->
  viewport = findTopWindow()?.win.visualViewport
  if not viewport?
    return (->)
  viewport.addEventListener('resize', callback)
  viewport.addEventListener('scroll', callback)
  ->
    viewport.removeEventListener('resize', callback)
    viewport.removeEventListener('scroll', callback)

# (Element) => { x: Number, y: Number }
offsetParentOrigin = (elem) ->
  parent = elem.offsetParent
  if not parent? or (parent is document.body and getComputedStyle(parent).position is 'static')
    { x: 0, y: 0 }
  else
    rect = parent.getBoundingClientRect()
    {
      x: rect.left + parent.clientLeft - parent.scrollLeft + window.scrollX
    , y: rect.top  + parent.clientTop  - parent.scrollTop  + window.scrollY
    }

export {
  getVisibleArea,
  offsetParentOrigin,
  watchVisibleArea,
}

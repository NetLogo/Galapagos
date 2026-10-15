# (Window) => Number
deviceWidth = (win = window) ->
  shortSide = Math.min(screen.width, screen.height)
  wideSide  = Math.max(screen.width, screen.height)
  if win.matchMedia('(orientation: landscape)').matches then wideSide else shortSide

# (Number) => Unit
fitViewportToWidth = (pageWidth) ->
  viewportMeta = document.querySelector('meta[name="viewport"]')
  if viewportMeta is null or not document.documentElement.classList.contains('nlw-phone')
    return

  shortSide = Math.min(screen.width, screen.height)
  fitScale  = Math.floor((deviceWidth() / pageWidth) * 1000) / 1000
  content   =
    if pageWidth > shortSide
      "width=#{pageWidth}, initial-scale=#{fitScale}"
    else
      'width=device-width, initial-scale=1'

  if viewportMeta.content isnt content
    viewportMeta.content = content

  return

# (Element) => Number
bodyMarginWidth = (body) ->
  bodyStyle = getComputedStyle(body)
  parseFloat(bodyStyle.marginLeft) + parseFloat(bodyStyle.marginRight)

export {
  bodyMarginWidth,
  deviceWidth,
  fitViewportToWidth,
}

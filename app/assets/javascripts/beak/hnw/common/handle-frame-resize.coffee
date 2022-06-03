import genPageTitle from "./gen-page-title.js"

# (() => DOMElement, () => Session) => Unit
handleFrameResize = (getActiveContainer, getSession) ->

  if parent isnt window

    width  = ""
    height = ""

    onInterval =
      ->

        activeContainer = getActiveContainer()
        session         = getSession()
        sessionName     = session?.modelTitle() ? ""

        if (activeContainer.scrollWidth  isnt width or
            activeContainer.scrollHeight isnt height or
            (session? and document.title isnt genPageTitle(sessionName)))

          if session?
            document.title = genPageTitle(sessionName)

          width  = activeContainer.scrollWidth
          height = activeContainer.scrollHeight

          if session? and session.widgetController.ractive.get("isHNWHost") isnt true
            parent.postMessage({
              width:  activeContainer.scrollWidth  + 330,
              height: activeContainer.scrollHeight +  60,
              title:  document.title,
              type:   "nlw-resize"
            }, "*")

    window.setInterval(onInterval, 200)

  return

export default handleFrameResize

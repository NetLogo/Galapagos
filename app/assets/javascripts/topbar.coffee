# (DOMElement, Array[{ text: String, url: String }]) => Unit
setHintBox = (topbarElem, links) ->

  hintBox = document.querySelector('.topbar-hint-box')

  if getComputedStyle(hintBox).display is 'none'

    listElem = document.querySelector('.topbar-hint-list')
    while listElem.lastChild
      listElem.removeChild(listElem.lastChild)

    template = document.querySelector('#hint-list-entry')

    links.forEach(({ text, url }) ->
      clone  = document.importNode(template.content, true)
      anchor = clone.querySelector(".topbar-hint-link")
      anchor.innerText = text
      anchor.href      = url
      listElem.appendChild(clone)
    )

    hintBox.style.left    = "#{topbarElem.getBoundingClientRect().left}px"
    hintBox.style.display = 'block'

  else
    hintBox.style.display = 'none'

  return

window.addEventListener('click', ({ target }) ->
  hintBox = document.querySelector('.topbar-hint-box')
  if not (target.classList.contains('topbar-label') or hintBox.contains(target))
    hintBox.style.display = 'none'
  return
)

window.addEventListener('load', ->

  relativizer     = if window.location.pathname.includes('/docs/') then "" else "../"

  authoringLink   = { text: "Authoring"        , url: "./#{relativizer}docs/authoring"   }
  differencesLink = { text: "What's Different?", url: "./#{relativizer}docs/differences" }
  faqLink         = { text: "FAQ"              , url: "./#{relativizer}docs/faq"         }
  docHintInfo     = { elemID: 'docs-label', links: [authoringLink, differencesLink, faqLink] }

  [docHintInfo].forEach(({ elemID, links }) ->
    elem = document.getElementById(elemID)
    elem.addEventListener('click', (-> setHintBox(elem, links)))
  )

)

import { markdownToHtml } from "/beak/tortoise-utils.js"

linkRegEx = /^(?:.*\s+|)(http[s]?:\/\/\S+)[\s\n]/gm

autoLinkUrls = (libraryMarkdown) ->
  matches = while ((a = linkRegEx.exec(libraryMarkdown)) isnt null)
    if a.index is linkRegEx.lastIndex
      linkRegEx.lastIndex++

    console.log(a.index, a[0], a[0].length, a[1], a[1].length)

    { url: a[1], index: (a.index + a[0].length - a[1].length - 1) }

  matches.reverse().reduce( (s, match) ->
    l = s.substring(0, match.index)
    r = s.substring(match.index + match.url.length)
    "#{l}[#{match.url}](#{match.url})#{r}"
  , libraryMarkdown)

relativizeProjectUrls = (origin, libraryMarkdown) ->
  player  = libraryMarkdown.replaceAll('https://netlogoweb.org/nettango-player', "#{origin}/nettango-player")
  builder = player.replaceAll('https://netlogoweb.org/nettango-builder', "#{origin}/nettango-builder")
  assets  = builder.replaceAll('https://netlogoweb.org/assets/nt-modelslib', "#{origin}/assets/nt-modelslib")
  assets

bindLibrary = (origin) ->
  fetch('assets/nt-modelslib/LIBRARY.md')
  .then( (response) ->
    if (not response.ok)
      throw new Error("#{response.status} - #{response.statusText}")
    response.text()

  ).then( (libraryMarkdown) =>
    libraryDiv  = document.getElementById('nettango-library')
    relativized = relativizeProjectUrls(origin, libraryMarkdown)
    linked      = autoLinkUrls(relativized)
    libraryHtml = markdownToHtml(linked)
    libraryDiv.innerHTML = libraryHtml

  ).catch( (error) =>
    # TBD...
    console.log(error)
    return
  )
  return

export { bindLibrary }

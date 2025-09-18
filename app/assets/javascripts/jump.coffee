modelEntryToComparable = (entry, statusObj) ->
  shortName = entry.split('/').slice(-1)[0].toLowerCase().replaceAll(" ", "-")
  status    = if statusObj? then statusObj.status ? 'unknown' else 'unknown'
  { entry, shortName, status }

createModelUrl = (location, matchEntry) ->
  matchAssets = matchEntry.replace("public/", "assets/")
  modelUrl    = new URL("#{matchAssets}.nlogox", location.origin)
  modelUrl

redirectToModel = (location, matchEntry, container) ->
  modelUrl = createModelUrl(location, matchEntry)
  window.location.href = "/launch##{modelUrl}"

# coffeelint: disable=max_line_length
template = """
<div class="jump-panel">
  {{#if links.length == 0}}
  <p>No matching models found for the search key <code>{{searchKey}}</code>.  Make sure the model you are looking for exists in the NetLogo models library.</p>
  {{else}}
  <p>Below are all models that match the <code>{{searchKey}}</code> search key.  You can click a link to open the model or copy the unique link to share it.</p>
  <ul class="jump-search-list">
    {{#links}}
    <li><a href="{{launchUrl}}">{{name}}</a>
      <ul><li>
        <button class="jump-link-button" on-click="['copy-link', jumpUrl]">copy shareable link</button>
        {{jumpUrl}}
      </li></ul>
    </li>
    {{/links}}
  </ul>
  {{/if}}
</div>
"""
# coffeelint: enable=max_line_length

createJumpLinks = (location, searchKeyMatches) ->
  searchKeyMatches.map( (m) ->
    name       = m.entry.split("/").slice(2).join("/")
    launchUrl  = "/launch##{createModelUrl(location, m.entry)}"
    jumpUrl = new URL("/jumpto##{m.shortName}", location.origin)
    { name, launchUrl, jumpUrl }
  )

createJumpRactive = (clipboard, location, container, searchKey, searchKeyMatches) ->
  links   = createJumpLinks(location, searchKeyMatches)
  ractive = new Ractive({
    el: container,
    data: { searchKey, links },
    template,
    on: {
      'hashchange': (_, newSearchKey, newSearchKeyMatches) ->
        @set('searchKey', newSearchKey)
        @set('links', createJumpLinks(location, newSearchKeyMatches))
        return

      'copy-link': (_, jumpUrl) ->
        await clipboard.writeText(jumpUrl.toString())
        return
    }
  })
  ractive

fetchModelList = () ->
  modelListResponse  = await fetch('./model/list.json')
  statusListResponse = await fetch('./model/statuses.json')
  if not modelListResponse.ok
    throw new Error("TODO: Better error; could not fetch list.json of models")
  else
    modelList      = await modelListResponse.json()
    statusList     = if statusListResponse.ok then await statusListResponse.json() else {}
    comparableList = modelList.map( (m) => modelEntryToComparable(m, statusList[m]) )
    return comparableList

routeJumpSearchKey = (location, comparableList) ->
  searchKey = location.hash.slice(1).toLocaleLowerCase()
  if searchKey.length is 0
    throw new Error("TODO: Better error; no search key given")

  else
    matched = false
    searchKeyMatches = comparableList.filter( (m) ->
      m.status isnt 'not_compiling' and m.shortName.startsWith(searchKey)
    )
    if searchKeyMatches.length is 1
      redirectToModel(location, searchKeyMatches[0].entry)
      matched = true

    exact = searchKeyMatches.filter( (m) -> m.shortName is searchKey )
    if exact.length is 1
      redirectToModel(location, exact[0].entry)
      matched = true

    return { matched, searchKey, searchKeyMatches }

export { fetchModelList, routeJumpSearchKey, createJumpRactive }

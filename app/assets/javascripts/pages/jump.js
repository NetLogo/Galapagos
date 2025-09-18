import { fetchModelList, routeJumpSearchKey, createJumpRactive } from '/jump.js'

window.ractive = null

const modelList   = await fetchModelList();
var searchResults = routeJumpSearchKey(document.location, modelList);

if (!searchResults.matched) {
  window.ractive = createJumpRactive(navigator.clipboard, document.location, 'jump-control', searchResults.searchKey, searchResults.searchKeyMatches);

  window.addEventListener("hashchange", (c) => {
    searchResults = routeJumpSearchKey(document.location, modelList);
    if (!searchResults.matched) {
      window.ractive.fire('hashchange', searchResults.searchKey, searchResults.searchKeyMatches);
    }
  });
}

import { listenForQueryResponses, createQueryMaker } from "/queries/debug-query-maker.js"

const modelContainer = document.querySelector('#model-container')
const params         = new URLSearchParams(window.location.search)

window.addEventListener("message", function(e) {

  switch (e.data.type) {

    case "nlw-resize": {

      var isValid = function(x) { return (typeof x !== "undefined" && x !== null) }

      var height = e.data.height
      var width  = e.data.width
      var title  = e.data.title

      // Quack, quack!
      // Who doesn't love duck typing? --Jason B. (11/9/15)
      if ([height, width, title].every(isValid)) {
        modelContainer.width               = width
        // When we reset the model height, we lose any scrolling that was in place,
        // so we "copy" it back to the main document.  -Jeremy B March 2021
        const modelScrollTop               = modelContainer.contentDocument.body.scrollTop
        modelContainer.height              = height
        document.documentElement.scrollTop = document.documentElement.scrollTop + modelScrollTop
        document.title                     = title
      }

      break;
    }

  }

})

if (params.has('debugQueries')) {
  window.makeQuery = createQueryMaker(modelContainer)
  listenForQueryResponses()
}

const url = `/assets/pages/iframe-test.html?${params.toString()}`;
modelContainer.contentWindow.location.replace(url);

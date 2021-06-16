ObjectUtils = Object.freeze({

  clone: (o) ->
    JSON.parse(JSON.stringify(o))

})

export default ObjectUtils

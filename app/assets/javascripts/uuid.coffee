# () => String
genUUID = ->

  replacer =
    (c) ->
      r = Math.random() * 16 | 0
      v = if c is 'x' then r else (r & 0x3 | 0x8)
      v.toString(16)

  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, replacer)

export default genUUID

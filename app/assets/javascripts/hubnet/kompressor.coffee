window.Kompressor = {

  # (Any) => String
  compress: (data) ->
    pako.deflate(JSON.stringify(data), { to: 'string' })

  # (String, Number) => Array[String]
  chunk: (string, length) ->
    chunks = []
    index  = 0
    while index < string.length
      chunks.push(string.substring(index, index + length))
      index += length
    chunks

  # (String) => Any
  decompress: (deflated) ->
    JSON.parse(pako.inflate(deflated, { to: 'string' }))

}

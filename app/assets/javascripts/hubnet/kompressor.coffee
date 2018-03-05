class window.Kompressor
  # (POJO) -> String
  @compress: (data) ->
    inflated = JSON.stringify(data)
    deflated = pako.deflate(inflated, { to: 'string' })
    deflated

  # (String, int) -> Array[String]
  @split: (string, length) ->
    parts = []
    index = 0
    while index < string.length
      parts.push(string.substring(index, index + length))
      index = index + length
    return parts

  # (String) -> POJO
  @decompress: (deflated) ->
    inflated = pako.inflate(deflated, { to: 'string' })
    data = JSON.parse(inflated)
    data

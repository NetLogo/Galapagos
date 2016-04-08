# input: number in [0, 140) range
# result: CSS color string
window.netlogoColorToCSS = (netlogoColor) ->
  [r,g,b] = array = netlogoColorToRGB(netlogoColor)
  a = if array.length > 3 then array[3] else 255
  if a < 255
    "rgba(#{r}, #{g}, #{b}, #{a/255})"
  else
    "rgb(#{r}, #{g}, #{b})"

# Since a turtle's color's transparency applies to its whole shape,  and not
# just the parts that use its default color, often we want to use the opaque
# version of its color so we can use global transparency on it. BCH 12/10/2014
window.netlogoColorToOpaqueCSS = (netlogoColor) ->
  [r,g,b] = array = netlogoColorToRGB(netlogoColor)
  "rgb(#{r}, #{g}, #{b})"

# (Number) => String
window.netlogoColorToHexString = (netlogoColor) ->
  rgb   = netlogoColorToRGB(netlogoColor)
  hexes = rgb.map((x) -> hex = x.toString(16); if hex.length is 1 then "0#{hex}" else hex)
  "##{hexes.join('')}"

# (String) => Number
window.hexStringToNetlogoColor = (hex) ->
  hexPair   = "([0-9a-f]{2})"
  rgbHexes  = hex.toLowerCase().match(new RegExp("##{hexPair}#{hexPair}#{hexPair}")).slice(1)
  [r, g, b] = rgbHexes.map((x) -> parseInt(x, 16))
  ColorModel.nearestColorNumberOfRGB(r, g, b)

window.netlogoColorToRGB = (netlogoColor) ->
  switch typeof(netlogoColor)
    when "number" then cachedNetlogoColors[Math.floor(netlogoColor*10)]
    when "object" then netlogoColor.map(Math.round)
    when "string" then netlogoBaseColors[netlogoColorNamesIndices[netlogoColor]]
    else console.error("Unrecognized color: #{netlogoColor}")

netlogoColorNamesIndices = {}
for color,i in ['gray',
                'red',
                'orange',
                'brown',
                'yellow',
                'green',
                'lime',
                'turqoise',
                'cyan',
                'sky',
                'blue',
                'violet',
                'magenta',
                'pink',
                'black',
                'white']
  netlogoColorNamesIndices[color] = i

# copied from api/Color.scala. note these aren't the same numbers as
# `map extract-rgb base-colors` gives you; see comments in Scala source
netlogoBaseColors = [
  [140, 140, 140], # gray       (5)
  [215,  48,  39], # red       (15)
  [241, 105,  19], # orange    (25)
  [156, 109,  70], # brown     (35)
  [237, 237,  47], # yellow    (45)
  [ 87, 176,  58], # green     (55)
  [ 42, 209,  57], # lime      (65)
  [ 27, 158, 119], # turquoise (75)
  [ 82, 196, 196], # cyan      (85)
  [ 43, 140, 190], # sky       (95)
  [ 50,  92, 168], # blue     (105)
  [123,  78, 163], # violet   (115)
  [166,  25, 105], # magenta  (125)
  [224, 126, 149], # pink     (135)
  [ 0,    0,   0], # black
  [255, 255, 255] # white
]

cachedNetlogoColors = for colorTimesTen in [0..1400]
  baseIndex = Math.floor(colorTimesTen / 100)
  [r,g,b] = netlogoBaseColors[baseIndex]
  step = (colorTimesTen % 100 - 50) / 50.48 + 0.012
  if step < 0
    r += Math.floor(r*step)
    g += Math.floor(g*step)
    b += Math.floor(b*step)
  else
    r += Math.floor((0xFF - r)*step)
    g += Math.floor((0xFF - g)*step)
    b += Math.floor((0xFF - b)*step)
  [r, g, b]

# input: number in [0, 140) range
# result: CSS color string
window.netlogoColorToCSS = (netlogoColor) ->
  switch typeof(netlogoColor)
    when "number" then cachedNetlogoColors[Math.floor(netlogoColor*10)]
    when "object" then colorArrayToCSS(netlogoColor)
    when "string" then netlogoColor
    else console.error("Unrecognized color: #{netlogoColor}")

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
    b += Math.floor((0XFF - b)*step)
  "rgb(#{r}, #{g}, #{b})"

colorArrayToCSS = (array) ->
  [r,g,b] = array
  a = if array.length > 3 then array[3] else 255
  if a < 255
    "rgba(#{r}, #{g}, #{b}, #{a/255})"
  else
    "rgb(#{r}, #{g}, #{b})"


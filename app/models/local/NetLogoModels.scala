package models.local

import org.nlogo.tortoise.Compiler

object NetLogoModels {

  def compileTermites =
    Compiler.compileProcedures(
      """
        |turtles-own [next steps]
        |
        |to setup
        |  clear-all
        |  __ask-sorted patches [
        |    if random 100 < 20
        |      [ set pcolor yellow ] ]
        |  crt 50
        |  __ask-sorted turtles [
        |    set color white
        |    setxy random-xcor random-ycor
        |    set size 3
        |    set next 1
        |  ]
        |end
        |
        |to go
        |  __ask-sorted turtles
        |    [ ifelse steps > 0
        |        [ set steps steps - 1 ]
        |        [ action
        |          wiggle ]
        |      fd 1 ]
        |end
        |
        |to wiggle
        |  rt random 50
        |  lt random 50
        |end
        |
        |to action
        |  ifelse next = 1
        |    [ searchforchip ]
        |    [ ifelse next = 2
        |      [ findnewpile ]
        |      [ ifelse next = 3
        |        [ putdownchip ]
        |        [ getaway ] ] ]
        |end
        |
        |to searchforchip
        |  if pcolor = yellow
        |    [ set pcolor black
        |      set color orange
        |      set steps 20
        |      set next 2 ]
        |end
        |
        |to findnewpile
        |  if pcolor = yellow
        |    [ set next 3 ]
        |end
        |
        |to putdownchip
        |  if pcolor = black
        |   [ set pcolor yellow
        |     set color white
        |     set steps 20
        |     set next 4 ]
        |end
        |
        |to getaway
        |  if pcolor = black
        |    [ set next 1 ]
        |end
        |""".stripMargin, -20, 20, -20, 20)

  def compileLife =
    Compiler.compileProcedures(
      """|patches-own [living? live-neighbors]
        |
        |to setup
        |  clear-all
        |  ask patches [ celldeath ]
        |  ask patch  0  0 [ cellbirth ]
        |  ask patch -1  0 [ cellbirth ]
        |  ask patch  0 -1 [ cellbirth ]
        |  ask patch  0  1 [ cellbirth ]
        |  ask patch  1  1 [ cellbirth ]
        |end
        |
        |to cellbirth set living? true  set pcolor green end
        |to celldeath set living? false set pcolor blue end
        |
        |to go
        |  ask patches [
        |    set live-neighbors count neighbors with [living?] ]
        |  ask patches [
        |    ifelse live-neighbors = 3
        |      [ cellbirth ]
        |      [ if live-neighbors != 2
        |        [ celldeath ] ] ]
        |end
        |""".stripMargin, -20, 20, -20, 20)

}

inv = (f) -> (x) ->
  not f(x)

checkIsGoodTurtle = (turtles) -> ([key, t]) ->
  t.id? or
    t.WHO? or
    t.who? or
    turtles[key]?

checkIsGoodLink = (links) -> ([key, l]) ->
  l.id? or
    (l.WHO is -1) or
    (l.END1? and l.END2?) or
    (l.end1? and l.end2?) or
    links[key]?

checkIsGoodPatch = (patches) -> ([key, p]) ->
  (p.pxcor? and p.pycor?) or patches[key]?

# (Object[Turtle], Object[Patch], Object[Link], AgentModel) => (String, Turtle|Patch|Link)?
findBaddie = (turtles, patches, links, agentModel) ->

  checkSet = (agentset, checker) ->
    if agentset?
      Object.entries(agentset).find(inv(checker))
    else
      undefined

  categories =
    [ [turtles, checkIsGoodTurtle(agentModel.turtles), "turtle"]
    , [links  , checkIsGoodLink(  agentModel.links  ), "link"  ]
    , [patches, checkIsGoodPatch( agentModel.patches), "patch" ]
    ]

  i = 0

  while i < categories.length
    [agentset, checker, type] = categories[i++]
    result                    = checkSet(agentset, checker)
    if result?
      return [type, result]

  undefined

export { findBaddie }

###

  type Metric = {
    interval: Number
  , reporter: () => Any
  }

  type VariableConfig = {
    name:           String
    parameterSpace: { type: "discreteValues", values: Array[Any] }
                  | { type: "range", min: Number, max: Number, interval: Number }
  }

  type BehaviorSpaceConfig =
    {
      experimentName:      String
      parameterSet:        { type: "discreteCombos",   combos:    Array[Object[Any]]    }
                         | { type: "cartesianProduct", variables: Array[VariableConfig] }
      repetitionsPerCombo: Number
      metrics:             Object[Metric]
      setup:               () => Unit
      go:                  () => Unit
      stopCondition:       () => Boolean
      iterationLimit:      Number
    }

  type Results = Array[{ config: Object[Any], results: Object[Object[Any]] }]

###

# (BehaviorSpaceConfig, (String, Any) => Unit, (Any) => Any) => Results
window.runBabyBehaviorSpace = (config, setGlobal, dump) ->

  { experimentName, parameterSet, repetitionsPerCombo, metrics, setup, go, stopCondition, iterationLimit } = config

  parameterSet =
    switch parameterSet.type
      when "discreteCombos"   then parameterSet.combos
      when "cartesianProduct" then genCartesianSet(parameterSet.variables)
      else                         throw new Exception("Unknown parameter set type: #{type}")

  flatten = (xs) -> [].concat(xs...)

  finalParameterSet =
    flatten(
      for combination in parameterSet
        for [1..repetitionsPerCombo]
          combination
    )

  window.Meta.behaviorSpaceName = experimentName ? "BabyBehaviorSpace"
  window.Meta.behaviorSpaceRun  = 0
  finalResults = for pSet in finalParameterSet
    for key, value of pSet
      setGlobal(key, value)
    results = executeRun(setup, go, stopCondition, iterationLimit, metrics, dump)
    window.Meta.behaviorSpaceRun = window.Meta.behaviorSpaceRun + 1
    { config: pSet, results }

  window.Meta.behaviorSpaceName = ""
  window.Meta.behaviorSpaceRun  = 0

  finalResults

# Code courtesy of Danny at https://stackoverflow.com/a/36234242/1116979
# (Array[Array[Any]]) => Array[Array[Any]]
cartesianProduct = (xs) ->
  xs.reduce(
    (acc, x) ->
      nested = acc.map((a) -> x.map((b) -> a.concat(b)))
      nested.reduce(((flattened, l) -> flattened.concat(l)), [])
  , [[]]
  )

# (Array[VariableConfig], Number) => Array[Object[Any]]
genCartesianSet = (variables) ->

  basicParameterSet =
    variables.map(
      ({ name, parameterSpace: { type, values, min, max, interval } }) ->
        values =
          switch type
            when "discreteValues" then values
            when "range"          then x for x in [min..max] by interval
            else                       throw new Exception("Unknown parameter space type: #{type}")
        values.map((value) -> { name, value })
    )

  condense = ((acc, { name, value }) -> acc[name] = value; acc)
  cartesianProduct(basicParameterSet).map((combo) -> combo.reduce(condense, {}))

# (() => Unit, () => Unit, () => Boolean, Number, Object[Metric], (Any) => Any) => Object[Object[Any]]
executeRun = (setup, go, stopCondition, iterationLimit, metrics, dump) ->

  iters = 0
  maxIters = if iterationLimit < 1 then -1 else iterationLimit

  measurements = {}

  measure =
    (i) ->

      ms = {}

      for name, { reporter, interval } of metrics when (interval is 0 or (i % interval) is 0)
        ms[name] = dump(reporter())

      if Object.keys(ms).length > 0
        measurements[i] = ms

      return

  setup()

  while not stopCondition() and iters < maxIters
    measure(iters)
    go()
    iters++

  measure(iters)

  measurements

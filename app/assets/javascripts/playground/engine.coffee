if not window.AgentModel?
  console.log('engine.js requires agentmodel.js!')

class Engine
  constructor: () ->
    @model = new window.AgentModel()


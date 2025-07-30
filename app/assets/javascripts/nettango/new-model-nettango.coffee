import { newCustomModel } from "/new-model.js"

netTangoCode =
  """
  to setup
    clear-all
    ; add setup code here
    reset-ticks
  end

  to go
    ; add go code here
    tick
  end
  """.trim()

newModelNetTango = newCustomModel(netTangoCode)

export default newModelNetTango

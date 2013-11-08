# This file declares all of the chat globals

DoubleList    = exports.DoubleList
LinkedHashSet = exports.LinkedHashSet

# Variables into which to cache jQuery selector results
$globals =
  $codeBufferWrapper:  undefined
  $chatterBuffer:      undefined
  $inputsWrapper:      undefined
  $onlineLog:          undefined
  $chatLog:            undefined
  $container:          undefined
  $agentType:          undefined
  $outputState:        undefined
  $errorPane:          undefined
  $errorPaneSpan:      undefined
  $chatPane:           undefined

# Other globals
globals =
  ccEditor:      undefined
  userName:      undefined
  usersArr:      undefined
  socket:        undefined
  scrollTimer:   undefined
  tortoiseUser:  "You"
  wontScroll:    true
  messageCount:  0
  agentTypes:    []
  logList:       []

exports.$ChatGlobals = $globals
exports.ChatGlobals  = globals

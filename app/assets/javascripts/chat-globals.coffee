# This file declares all of the chat globals

DoubleList    = exports.DoubleList
LinkedHashSet = exports.LinkedHashSet

# Variables into which to cache jQuery selector results
$globals =
  $inputBuffer:   undefined
  $onlineLog:     undefined
  $chatLog:       undefined
  $container:     undefined
  $copier:        undefined
  $textCopier:    undefined
  $agentType:     undefined
  $outputState:   undefined
  $errorPane:     undefined
  $errorPaneSpan: undefined
  $chatPane:      undefined

# Other globals
globals =
  userName:      undefined
  usersArr:      undefined
  socket:        undefined
  scrollTimer:   undefined
  tortoiseUser:  "You"
  wontScroll:    true
  messageCount:  0
  messageList:   new DoubleList(20)
  agentTypes:    new LinkedHashSet()
  logList:       []

exports.$ChatGlobals = $globals
exports.ChatGlobals  = globals

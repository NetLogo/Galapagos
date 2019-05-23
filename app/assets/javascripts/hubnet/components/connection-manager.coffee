window.RactiveConnectionManager = RactiveView.extend({

  data: -> {
    connected:  false, # Boolean
    log:        ""     # String
    logEntries: []     # Array[String]
  }

  # (String) => Unit
  appendToLog: (text) ->

    log        = @get('log')
    logEntries = @get('logEntries')

    if logEntries.length > 0 and logEntries[logEntries.length - 1] is text
      @set('log', "#{log}+")
    else
      logEntries.push(text)
      @set('log', "#{log}\n#{text}")

    logArea           = document.getElementById('connection-log')
    logArea.scrollTop = logArea.scrollHeight

    return

  # () => Unit
  clear: ->
    @set('log'       , '')
    @set('logEntries', [])
    return

  onrender: ->
    @on('clientele-log-clear', (=> @clear()))
    return

  template:
    """
    <div id="clientele-component" class="netlogo-client-component" >
      <button class="netlogo-ugly-button" on-click="server-connect" {{# connected }}disabled{{/}} >Act as Server</button>
      <button class="netlogo-ugly-button" on-click="client-connect" {{# connected }}disabled{{/}} >Connect as Client</button>
      <button class="netlogo-ugly-button" on-click="disconnect" {{# !connected }}disabled{{/}} >Disconnect</button>
      <button class="netlogo-ugly-button" on-click="clientele-log-clear" >Clear Log</button>
      <textarea id="connection-log" value="{{log}}" disabled style="height:140px;"></textarea>
    </div>
    """

})

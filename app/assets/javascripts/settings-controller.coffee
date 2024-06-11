import { WIP_INFO_FORMAT_VERSION } from '/beak/wip-data.js'

locales = [
  { code: "zh_cn", description: "Chinese, simplified - 中文 (简体)", languageCode: "zh" }
, { code: "en_us", description: "English - United States", languageCode: "en" }
, { code: "es_es", description: "Spanish - Español", languageCode: "es" }
, { code: "ja_jp", description: "Japanese  - 日本語", languageCode: "ja" }
, { code: "pt_pt", description: "Portuguese - Português", languageCode: "pt" }
]
'''
data = {
  locales: locales,
  isConnectedToGitHub: false
}
'''
settings = new Map()
settings.set('locale', {
  def: ''
, ractiveName: 'locale'
, in:  ((l) -> l)
, out: ((l) -> l)
})

settings.set('workInProgress.enabled', {
  def: 'Enabled'
, ractiveName: 'workInProgressSetting'
, in:  ((wipEnabled) -> if wipEnabled then 'Enabled' else 'Disabled')
, out: ((value)      -> value is 'Enabled')
})
settings.set('useVerticalLayout', {
  def: 'below'
, ractiveName: 'verticalLayoutSetting'
, in:  ((useVerticalLayout) -> if useVerticalLayout then 'below' else 'right')
, out: ((value)             -> value is 'below')
})


settings.set('githubToken', {
  def: ''
, ractiveName: 'githubToken'
, in:  ((token) -> token)
, out: ((token) -> token)
})

settings.set('githubUser', {
  def: ''
, ractiveName: 'githubUser'
, in:  ((user) -> user)
, out: ((user) -> user)
})

settings.set('repoName', {
  def: ''
, ractiveName: 'repoName'
, in:  ((repo) -> repo)
, out: ((repo) -> repo)
})

settingNames = Array.from(settings.keys())
settingNames.push('githubToken')

toggleGitHubConnection: (event) ->
  console.log("in toggle")
  if @get('isConnectedToGitHub')
    @disconnectFromGitHub()
    disconnectFromGitHub.call(this)
  else
    @connectToGitHub()
    connectToGitHub.call(this)

disconnectFromGithub = ->
  localStorage.removeItem('accessToken') 
  document.cookie = 'accessToken=; Max-Age=-99999999;'  
  @set('isConnectedToGitHub', false)
  console.log("Disconnected from GitHub")

'''
connectToGitHub = ->
  console.log("Update Gist passed")
  authWindow = window.open('https://alison-nlw-gh-oauth.onrender.com/auth/github', 'githubOauth', 'width=800,height=600')

  checkAccessTokenSet = =>
    console.log("document cookie: ")
    console.log("cookie")
    accessToken = document.cookie;
    console.log(accessToken)
    if accessToken
      accessTokenValue = accessToken.split('=')[1]
      console.log("Access token found in cookies:", accessTokenValue)
      localStorage.setItem('accessToken', accessTokenValue)
      @set('isConnectedToGitHub', true)
      alert("AccessToken is set")
      return true
    else
      console.log("Access token not found in cookies yet.")
      return false

  waitForAccessToken = =>
    if checkAccessTokenSet()
      console.log("Access token is set. Proceeding with authentication.")
    else
      setTimeout(waitForAccessToken, 1000)

  waitForAccessToken()
'''


template = """
<div class="settings-panel">
  <h1 class="settings-header">NetLogo Web Settings</h1>

  <label class="setting-label">
    Command center, NetLogo code, and model info position:
  </label>
  <div class="setting-control">
    <select value={{verticalLayoutSetting}} on-change="setting-changed">
      <option value="below">Below the model</option>
      <option value="right">To the right of the model</option>
    </select>
  </div>

  <label class="setting-label">
    Automatically save changes made to models and reuse them when reloading:
  </label>
  <div class="setting-control">
    <select value={{workInProgressSetting}} on-change="setting-changed">
      <option>Enabled</option>
      <option>Disabled</option>
    </select>
  </div>

  <div class="setting-label">
    Language override (for runtime errors only):
  </div>
  <div class="setting-control">
    <select value={{locale}} on-change="setting-changed">
      <option value="">Use browser language or English when unavailable</option>
      {{#locales}}
      <option value={{code}}>{{description}}</option>
      {{/}}
    </select>
  </div>
  
  <div class="netlogo-export-wrapper">
    <span style="margin-right: 4px;">Connect to Github:</span>
    <button class="netlogo-ugly-button" on-click="toggleGitHubConnection">
      {{#if isConnectedToGitHub}}Disconnect{{else}}Connect{{/if}}
    </button>
  </div>

</div>


<h1 class="settings-subheader">Works in Progress</h1>
<div class="description">Here are all the models you have made changes to in NetLogo Web.</div>

<ul>
  {{#each workInProgressLinks}}
    <li><a href="{{url}}">{{modelTitle}}</a> {{storageTag}} <div>{{dataAccessed}}</div></li>
  {{/each}}
</ul>

"""
#Formatting Links for HTML display
formatLinks = (wipStorage) ->
  results = []

  for url, model of wipStorage.inProgress
    if model.title and model.timeStamp and not(url.startsWith('disk') or url.startsWith('new')) and
    model.version is WIP_INFO_FORMAT_VERSION
      storageTagOutput = ""
      storageTag = url.split(':').shift()
      if storageTag isnt "url"
        storageTagOutput = " (tag: #{storageTag})"
        formattedUrl = "/launch?storageTag=#{storageTag}##{window.location.protocol}//" + url.replace(/.*:\/\//, '')
      else
        formattedUrl = "/launch##{window.location.protocol}//" + url.replace(/^url:\/\//, '')

      results.unshift({
        modelTitle: model.title,
        url: formattedUrl,
        dataAccessed: (new Date(model.timeStamp)).toLocaleString(undefined,
        { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' })
        storageTag: storageTagOutput
        timeStamp: model.timeStamp
      })

  results.sort((b, a) -> a.timeStamp - b.timeStamp)

  results

# (HtmlDivElement, NamespaceStorage) => Ractive
createSettingsRactive = (container, storage, wipStorage) ->
  data = { locales , isConnectedToGitHub: false}
  data.workInProgressLinks = formatLinks(wipStorage)
  settingNames.forEach( (name) ->
    setting = settings.get(name)
    data[setting.ractiveName] = if storage.hasKey(name)
      setting.in(storage.get(name))
    else
      setting.def
  )

  ractive = new Ractive({
    el: container
  , data
  , template
  , on: {
    'setting-changed': (_) ->
      settingNames.forEach( (name) =>
        setting = settings.get(name)
        value   = @get(setting.ractiveName)
        if setting.def is value
          storage.remove(name)
        else
          storage.set(name, setting.out(value))

        return
      )
    'toggleGitHubConnection': (event) ->
      if @get('isConnectedToGitHub')
        console.log("Disconnecting from GitHub...")
        @set('isConnectedToGitHub', false)
      else
        console.log("Connecting to GitHub...")
        @connectToGitHub()
  }
  , connectToGitHub : -> #arrow tells its a function 
      console.log("connectToGithub ractive")
      @set('isConnectedToGitHub', true)
      console.log("HIIII")

      console.log("Update Gist passed")
      authWindow = window.open('https://alison-nlw-gh-oauth.onrender.com/auth/github', 'githubOauth', 'width=800,height=600')


  })
  ractive

export { createSettingsRactive , locales }

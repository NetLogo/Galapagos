import { WIP_INFO_FORMAT_VERSION } from '/beak/wip-data.js'

locales = [
  { code: "zh_cn", description: "Chinese, simplified - 中文 (简体)", languageCode: "zh" }
, { code: "en_us", description: "English - United States", languageCode: "en" }
, { code: "es_es", description: "Spanish - Español", languageCode: "es" }
, { code: "ja_jp", description: "Japanese  - 日本語", languageCode: "ja" }
, { code: "pt_pt", description: "Portuguese - Português", languageCode: "pt" }
]

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

settingNames = Array.from(settings.keys())

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
  data = { locales }
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

      return
  }
  })
  ractive

export { createSettingsRactive , locales }

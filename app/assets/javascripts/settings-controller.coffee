locales = [
  { code: "zh_cn", description: "Chinese, simplified - 中文 (简体)" }
, { code: "en_us", description: "English, United States" }
]

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
"""

createSettingsRactive = (container) ->
  ractive = new Ractive({
    el:   container
  , data: (() -> {
      locales
    , locale: ""
    , workInProgressSetting: "Enabled"
    , verticalLayoutSetting: "below"
    })
  , template
  , on: {
    'setting-changed': (_) ->
      #console.log(arguments)
      #console.log(@get('locale'), @get('workInProgressSetting'), @get('verticalLayoutSetting'))

      return
  }
  })
  ractive

export { createSettingsRactive }

RactiveAsyncLoader = Ractive.extend({
  data: () -> {
    spinCount: 8
    loading:   true      # Boolean
    error:     undefined # String
    class:     undefined # String
  },

  partials: {
    # The SVGs are just a hardcopy of what the spinner view spits out into the simulation/other pages.  -Jeremy B August
    # 2025
    # coffeelint: disable=max_line_length
    loadingBar: """
      <div style="display: flex; align-items: center; justify-content: center; position: fixed; background: #999; width: 100%; height: 100%;">

      <div class="spinner">

        <svg class="spinner-img turtle1" xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 50 55">
          <polygon points="22,0 0,49 22,40 44,49" style="fill: rgba(255, 255, 255, 0.125);" transform="rotate(45.0, 22, 24)">
          </polygon>
        </svg>

        <svg class="spinner-img turtle2" xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 50 55">
          <polygon points="22,0 0,49 22,40 44,49" style="fill: rgba(255, 255, 255, 0.25);" transform="rotate(90.0, 22, 24)">
          </polygon>
        </svg>

        <svg class="spinner-img turtle3" xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 50 55">
          <polygon points="22,0 0,49 22,40 44,49" style="fill: rgba(255, 255, 255, 0.375);" transform="rotate(135.0, 22, 24)">
          </polygon>
        </svg>

        <svg class="spinner-img turtle4" xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 50 55">
          <polygon points="22,0 0,49 22,40 44,49" style="fill: rgba(255, 255, 255, 0.5);" transform="rotate(180.0, 22, 24)">
          </polygon>
        </svg>

        <svg class="spinner-img turtle5" xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 50 55">
          <polygon points="22,0 0,49 22,40 44,49" style="fill: rgba(255, 255, 255, 0.625);" transform="rotate(225.0, 22, 24)">
          </polygon>
        </svg>

        <svg class="spinner-img turtle6" xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 50 55">
          <polygon points="22,0 0,49 22,40 44,49" style="fill: rgba(255, 255, 255, 0.75);" transform="rotate(270.0, 22, 24)">
          </polygon>
        </svg>

        <svg class="spinner-img turtle7" xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 50 55">
          <polygon points="22,0 0,49 22,40 44,49" style="fill: rgba(255, 255, 255, 0.875);" transform="rotate(315.0, 22, 24)">
          </polygon>
        </svg>

        <svg class="spinner-img turtle8" xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 50 55">
          <polygon points="22,0 0,49 22,40 44,49" style="fill: rgba(255, 255, 255, 1.0);" transform="rotate(360.0, 22, 24)">
          </polygon>
        </svg>

      </div>
      </div>
      """
      # coffeelint: enable=max_line_length

    errorMessage: """
      <div class="async-loader-error">
        <p>Error loading content.</p>
        <p>{{error}}</p>
      </div>
    """
  },

  computed: {
    display: ->
      if @get('loading') then 'none' else 'contents'
  }

  template: """
    <div class="async-loader {{class}}">
      {{#if loading}}
        {{> loadingBar }}
      {{else}}
        {{#error}}
          {{> errorMessage }}
        {{/error}}
      {{/if}}
      <div class="async-loader-content" style="display: {{display}}">
        {{ yield }}
      </div>
    </div>"""
})

export default RactiveAsyncLoader

RactiveAsyncLoader = Ractive.extend({
  data: {
    loading: true      # Boolean
    error:   undefined # String
    class:   undefined # String
  },

  partials: {
    loadingBar: """
      <div class="async-loader spinner">
        <img src="/assets/images/thin-strip-loader.gif" alt="Loading..." />
      </div>
    """

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
    </div>
  """,
})

export default RactiveAsyncLoader

hostPrefix = "assets/nt-modelslib/"

window.RactiveProjectChooser = Ractive.extend({

  data: () -> {
    isActive: false # Boolean
  , top:      "50px" # String
  }

  show: (top = "50px") ->
    @set("isActive", true)
    @set("top",      top)
    return

  loadLibrary: (libraryJson) ->
    projects = libraryJson.models.sort((m1, m2) ->
      if m1.folder < m2.folder
        -1
      else if m1.folder > m2.folder
        1
      else # same folder
        if m1.name < m2.name
          -1
        else if m1.name > m2.name
          1
        else
          0
    )
    @set('projects', projects)
    $('#ntb-ntjson-chooser').chosen({ search_contains: true, width: "95%" })
    return

  on: {

    'complete': (_) ->
      fetch('assets/nt-modelslib/library.json')
      .then( (response) ->
        if (not response.ok)
          throw new Error("#{response.status} - #{response.statusText}")
        response.json()

      ).then( (project) =>
        @loadLibrary(project)

      ).catch( (error) =>
        @fire('ntb-error', {}, 'load-library-json', error)
        return
      )
      return

    'load-project': (_) ->
      @set("isActive", false)
      # We can't use normal Ractive data binding for the `value` of the select, as Chosen doesn't
      # cause updates when it sets it. -Jeremy B May 2021
      select     = @find("#ntb-ntjson-chooser")
      projectUrl = hostPrefix + select.value
      @fire('ntb-load-remote-project', projectUrl)
      return

    'cancel': () ->
      @set("isActive", false)
      return

  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-dialog-overlay" {{# !isActive }}hidden{{/}}>
      <div class="ntb-confirm-dialog" style="margin-top: {{ top }}">
        <div class="ntb-confirm-header">Choose a Library Model</div>
        <div class="ntb-confirm-text">
          <span>Pick a NetTango project from the NetTango project library.  Note that the NetTango project library is still a work in progress, so you may encounter issues with some projects.</span>
          <div class="ntb-netlogo-model-chooser">
            <select id="ntb-ntjson-chooser">
              {{# projects }}
                <option value="{{path}}">{{folder}} / {{name}}</option>
              {{/projects}}
            </select>
          </div>
        </div>
        <input class="widget-edit-text ntb-confirm-button" type="button" on-click="load-project" value="Load the project">
        <input class="widget-edit-text ntb-confirm-button" type="button" on-click="cancel" value="Cancel">
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})

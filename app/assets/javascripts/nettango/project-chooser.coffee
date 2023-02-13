import RactiveModalDialog from "./modal-dialog.js"

hostPrefix = "assets/nt-modelslib/"

RactiveProjectChooser = RactiveModalDialog.extend({

  data: () -> {
    preRenderContent: true # Boolean
  , approve:          { text: "Load the project", event: "ntb-load-remote-project", argsMaker: () => @getProjectInfo() }
  , deny:             { text: "Cancel" }
  }

  getProjectInfo: () ->
    # We can't use normal Ractive data binding for the `value` of the select, as Chosen doesn't
    # cause updates when it sets it. -Jeremy B May 2021
    select     = @find("#ntb-ntjson-chooser")
    projectUrl = hostPrefix + select.value
    [projectUrl]

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
        @fire('nettango-error', {}, 'load-library-json', error)
        return
      )
      return

  }

  partials: {
    headerContent: "Choose a Library Project"
    dialogContent:
      # coffeelint: disable=max_line_length
      """
      <div class="ntb-dialog-text">
        <span>Pick a NetTango project from the NetTango project library.  Note that the NetTango project library is still a work in progress, so you may encounter issues with some projects.</span>
        <div class="ntb-netlogo-model-chooser">
          <select id="ntb-ntjson-chooser">
            {{# projects }}
              <option value="{{path}}">{{folder}} / {{name}}</option>
            {{/projects}}
          </select>
        </div>
      </div>
      """
      # coffeelint: enable=max_line_length
  }
})

export default RactiveProjectChooser

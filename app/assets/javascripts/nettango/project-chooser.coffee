import RactiveModalDialog from "./modal-dialog.js"
import RactiveSearchableSelect from "/beak/widgets/ractives/subcomponent/searchable-select.js"

hostPrefix = "assets/nt-modelslib/"

RactiveProjectChooser = RactiveModalDialog.extend({

  components: {
    searchableSelect: RactiveSearchableSelect
  }

  data: () -> {
    preRenderContent: true # Boolean
  , approve: {
    text:  "Load the project"
  , event: "ntb-load-remote-project"
  , argsMaker: () => @getProjectInfo()
  }
  , deny: {
    text: "Cancel"
  }
  , projectOptions:  [] # Array[{value: String, label: String}]
  , selectedProject: null # String | null
  }

  getProjectInfo: () ->
    projectUrl = hostPrefix + @get('selectedProject')
    [projectUrl]

  loadLibrary: (libraryJson) ->
    projects = libraryJson.models.sort((m1, m2) ->
      if m1.folder < m2.folder
        -1
      else if m1.folder > m2.folder
        1
      else
        if m1.name < m2.name
          -1
        else if m1.name > m2.name
          1
        else
          0
    )
    options = projects.map((p) -> { value: p.path, label: "#{p.folder} / #{p.name}" })
    @set('projectOptions', options)
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
          <searchableSelect
            options="{{projectOptions}}"
            selected="{{selectedProject}}"
            placeholder="Choose a project" />
        </div>
      </div>
      """
      # coffeelint: enable=max_line_length
  }
})

export default RactiveProjectChooser

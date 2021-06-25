import RactiveModelDialog from "./modal-dialog.js"

RactiveConfirmDialog = RactiveModelDialog.extend({

  data: () -> {
    text: null  # String
  }

  # (ShowOptions) => Unit
  show: (options) ->
    @set("text", options?.text ? "Are you sure?")
    propNames = ['active', 'top', 'approve', 'deny']
    propNames.forEach( (propName) =>
      if options[propName]? then @set(propName, options[propName])
    )
    @_super()
    return

  partials: {
    headerContent: "Confirm"
    dialogContent: """<div class="ntb-dialog-text">{{ text }}</div>"""
  }
})

export default RactiveConfirmDialog

import RactiveModalDialog from "./modal-dialog.js"

RactiveConfirmDialog = RactiveModalDialog.extend({

  data: () -> {
    text:         null                  # String
    extraClasses: 'ntb-confirm-overlay' # String
  }

  # (ShowOptions) => Unit
  show: (options) ->
    @set("text", options?.text ? "Are you sure?")
    propNames = ['active', 'approve', 'deny']
    propNames.forEach( (propName) =>
      if options[propName]? then @set(propName, options[propName])
    )
    @_super(options['top'], options['left'])
    return

  partials: {
    headerContent: "Confirm"
    dialogContent: """<div class="ntb-dialog-text">{{ text }}</div>"""
  }
})

export default RactiveConfirmDialog

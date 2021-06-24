import RactiveModelDialog from "./modal-dialog.js"

RactiveConfirmDialog = RactiveModelDialog.extend({

  data: () -> {
    text: null  # String
  }

  # (ShowOptions) => Unit
  show: (options) ->
    @_super(options)
    @set("text", options?.text ? "Are you sure?")
    return

  partials: {
    dialogContent: """<div class="ntb-dialog-text">{{ text }}</div>"""
  }
})

export default RactiveConfirmDialog

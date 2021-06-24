import RactiveModelDialog from "./modal-dialog.js"

RactiveConfirmDialog = RactiveModelDialog.extend({

  data: () -> {
    text: null  # String
  }

  # (ShowOptions, Int, Int) => Unit
  show: (options, left = 300, top = 50) ->
    @_super(options, left, top)
    @set("text", options?.text ? "Are you sure?")
    return

  partials: {
    dialogContent: """<div class="ntb-dialog-text">{{ text }}</div>"""
  }
})

export default RactiveConfirmDialog

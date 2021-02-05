window.RactiveBlockPreview = Ractive.extend({

  data: () -> {
    block:       undefined # NetTangoBlock
    code:        undefined # String
    blockStyles: undefined # NetTangoBlockStyles
  }

  on: {

    # (Context) => Unit
    'render': (_) ->
      block = @get("block")

      if not block.id?
        block.id = 0

      blockStyles = @get("blockStyles")

      defs = {
        version: 5
        height: 300
        width: 400
        expressions: NetTangoBlockDefaults.expressions
        blockStyles: blockStyles
      }

      sample = {
        id: block.id + 1,
        action: "Preview Command",
        format: 'show "hello!"',
        required: false
      }

      if block.builderType? and block.builderType is "Procedure"
        chain        = { x: 5, y: 5, blocks: [ block ] }
        defs.blocks  = [ block, sample ]
        defs.program = { chains: [ chain ] }

      else
        proc = {
          id: block.id + 1,
          action: "Preview Proc",
          required: true,
          placement: NetTango.blockPlacementOptions.STARTER,
          format: "to preview",
          limit: 1
        }
        chain = { x: 5, y: 5, blocks: [ proc, block ] }
        defs.blocks = [ proc, sample, block ]
        defs.program = { chains: [ chain ] }

      try
        NetTango.restore("NetLogo", @containerId, defs, NetTangoRewriter.formatDisplayAttribute)
      catch ex
        # hmm, what to do with an error, here?
        console.log(ex)
        return

      NetTango.onProgramChanged(@containerId, (ntContainerId, event) => @updateNetLogoCode())
      @updateNetLogoCode()

      return

  }

  containerId: "ntb-block-preview-canvas"

  resetNetTango: () ->
    block = @get("block")
    defs  = NetTango.save(@containerId)
    defs.blocks = defs.blocks.map( (b) -> if b.id is block.id then block else b )

    try
      NetTango.restore("NetLogo", @containerId, defs, NetTangoRewriter.formatDisplayAttribute)
    catch ex
      # hmm, what to do with an error, here?
      console.log(ex)
      return

    @updateNetLogoCode()

    return

  updateNetLogoCode: () ->
    code = NetTango.exportCode(@containerId).trim()
    @set("code", code)
    return

  components: {
    codeMirror: RactiveCodeMirror
  }

  template:
    """
    <div class="ntb-block-preview">

    <div>Preview</div>

    <codeMirror
      id="ntb-block-preview-code"
      mode="netlogo"
      code="{{ code }}"
      config="{ readOnly: 'nocursor' }"
      extraClasses="[ 'ntb-code', 'ntb-code-readonly' ]"
    />

    <div id="ntb-block-preview" class="ntb-canvas">
      <div id="ntb-block-preview-canvas" />
    </div>

    </div>
    """
})

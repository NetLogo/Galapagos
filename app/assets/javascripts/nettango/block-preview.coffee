import NetTangoRewriter from "./rewriter.js"
import RactiveCodeMirror from "./code-mirror.js"
import NetTangoBlockDefaults from "./block-defaults.js"

RactiveBlockPreview = Ractive.extend({

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
        version:     6
        height:      300
        width:       400
        blockStyles: blockStyles
      }

      sampleDefs = @makeSampleDefs(block)

      blockIns = {
        definitionId: block.id
        instanceId:   0
      }

      if block.builderType? and block.builderType is "Procedure"
        blocks = if block.isTerminal or ((block.allowedTags?.tags ? []).length isnt 0)
          [blockIns]
        else
          sampleIns = {
            definitionId: block.id + 1
            instanceId:   0
          }
          [blockIns, sampleIns]

        chain        = { x: 5, y: 5, blocks: blocks }
        defs.blocks  = [ block, sampleDefs... ]
        defs.program = { chains: [ chain ] }

      else
        procDef = {
          id:         block.id + 1
          action:     "Preview Procedure"
          isRequired: true
          placement:  NetTango.blockPlacementOptions.STARTER
          format:     "to preview"
          limit:      1
        }
        procIns = {
          definitionId: block.id + 1
          instanceId:   0
        }
        chain = { x: 5, y: 5, blocks: [ procIns, blockIns ] }
        defs.blocks = [ procDef, sampleDefs..., block ]
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

    'end-drag': (context) ->
      context.event.preventDefault()
      context.event.stopPropagation()
      return false

  }

  containerId: "ntb-block-preview-canvas"

  makeSampleDefs: (block) ->
    untagged = {
      id:         block.id + 1
      action:     "Preview Command"
      format:     'show "hello!"'
      isRequired: false
    }
    blockTags = block.allowedTags?.tags ? []
    allTags   = blockTags.concat(block.clauses.flatMap( (clause) -> clause.allowedTags?.tags ? [] ))
    tags      = allTags.filter( (tag, index, arr) -> arr.indexOf(tag) is index )
    tagged    = tags.map( (tag, index) ->
      {
        id:         block.id + index + 2
        action:     "#{tag}-tag Command"
        format:     "show \"hello, #{tag}!\""
        isRequired: false
        tags:       [tag]
      }
    )
    [untagged, tagged...]

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

    <div id="ntb-block-preview" class="ntb-canvas" draggable="true" on-dragstart="end-drag">
      <div id="ntb-block-preview-canvas" />
    </div>

    </div>
    """
})

export default RactiveBlockPreview

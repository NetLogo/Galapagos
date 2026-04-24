import { followAgentWithZoom } from '../draw/window-generators.js'
import { getDimensions } from "../draw/perspective-utils.js"
import { getClickedAgents, agentToContextMenuOption } from "../view-context-menu-utils.js"
import { getEquivalentAgent } from "../draw/agent-conversion.js"
import RactiveAgentVarField from './agent-var-field.js'
import RactiveCommandInput from "./command-input.js"
import { isToggleKeydownEvent } from '../accessibility/utils.js'

{ Perspective: { Ride, Follow, Watch } } = tortoise_require('engine/core/observer')

RactiveAgentMonitor = Ractive.extend({
  components: {
    agentVarField: RactiveAgentVarField
  , commandInput:  RactiveCommandInput
  }

  data: -> {
    agent:           undefined # Agent; a reference to the actual agent from the engine
  , isEditing:       undefined # Boolean
  , checkIsReporter: undefined # (String) => Boolean
  , setInspect:      undefined # (SetInspectAction) -> Unit
  , viewController:  undefined # ViewController; from which this agent monitor is taking its ViewWindow

    # viewModelAgent is the equivalent agent from the ViewController's AgentModel.
    # It should be kept in sync with the `agent` data.
  , viewModelAgent:  undefined # Agent
  , agentType:       undefined # 'turtle' | 'patch' | 'link'; should be kept in sync with the `agent` data
  , viewWindow:      undefined # View; a reference to the View associated with the current agent
  , windowGenerator: undefined # result of `followAgentWithZoom`; see "window-generators.coffee"
  , zoomLevel:       0.35      # Number; represents how much of the screen the agent takes up

    # () -> Unit
  , replaceView: ->
      if not @get('viewModelAgent')?
        return
      if @get('viewWindow')?
        @get('viewWindow').destructor()
      viewController = @get('viewController')
      { worldWidth, worldHeight } = viewController.getWorldShape()
      windowGenerator = followAgentWithZoom(
        @find('.inspection-agent-monitor-view-container').offsetWidth,
        @get('viewModelAgent'),
        @get('zoomLevel'),
        Math.min(worldWidth, worldHeight) / 2
      )
      viewWindow = viewController.getNewView(
        @find('.inspection-agent-monitor-view-container'),
        'world',
        windowGenerator
      )
      @set({ viewWindow, windowGenerator })
      # Repaints the view; we do this instead of calling repaint directly because this also accounts for zoom.
      @get('zoomView')(@get('zoomLevel'))
      return

    # (Number) -> Unit
  , zoomView: (zoomLevel) ->
      @get('windowGenerator').zoomLevel = zoomLevel
      @get('viewWindow').repaint()
      return

    # (Turtle|Patch|Link|Observer) -> String
  , printProperties: (agent) ->
      pairList = for varName in agent.varNames()
        "#{varName}: #{agent.getVariable(varName)}"
      pairList.join("<br/>")
  }

  computed: {
    # () -> Array[String]
    varNames: -> @get('agent')?.varNames() ? []

    # () -> Boolean
    agentIsDead: -> @get('agent')?.isDead() ? false

    # () -> String
    agentName: -> @get('agent')?.getName() ? ''

    # () -> { agentType: AgentType, agents: Array[Agent] }
    targetedAgentObj: ->
      agentType = switch @get('agentType')
        when 'turtle' then 'turtles'
        when 'patch' then 'patches'
        when 'link' then 'links'
      agent = @get('agent')
      { agentType, agents: [agent] }

    # () -> Boolean
    isWatching: ->
      agent    = @get('agent')
      observer = world.observer
      persp    = observer.getPerspective()
      (persp is Ride or persp is Follow or persp is Watch) and observer.subject() is agent
  }

  # () -> Unit
  onrender: ->
    # We want to run `updateView` and `zoomView` only after the instance has been rendered to the DOM, but Ractive
    # observers initialize before rendering. And for some reason, using the `defer` option does not work
    # (see Ractive API).
    @_wasEverDead = false
    @_syncAgentData(@get('agent'))
    @get('replaceView')()
    return

  # () -> Unit
  onteardown: ->
    @get('viewWindow')?.destructor()
    return

  on: {
    'world-might-change': ({ modelChanged }) ->
      # Once an agent has died, stop updating entirely. The engine reuses turtle objects — a new turtle
      # with the same `who` number would otherwise hijack this monitor and start being tracked here.
      if @_wasEverDead or not modelChanged
        return
      @update('agent')
      if @get('agent').isDead()
        @_wasEverDead = true
        # Switch the view to follow the patch at the turtle's last location so it stays put
        # and remains zoomable, rather than tracking a new turtle with the same `who` number.
        viewModelAgent = @get('viewModelAgent')
        if viewModelAgent?.xcor?
          deathPatch = world.getPatchAt(Math.round(viewModelAgent.xcor), Math.round(viewModelAgent.ycor))
          if deathPatch?
            patchViewModel = @get('viewController').getModel().patches[deathPatch.id]
            if patchViewModel?
              @set('viewModelAgent', patchViewModel)
              @get('replaceView')()
        return
      # If the view was not set up on onrender (because the agent wasn't in the view model yet mid-tick),
      # retry now that the model has settled.
      if not @get('viewWindow')?
        @_syncAgentData(@get('agent'))
        @get('replaceView')()
      return

    'watch-button-clicked': ->
      observer = world.observer
      persp = observer.getPerspective()
      inspectedAgent = @get('agent')
      if (persp is Ride or persp is Follow or persp is Watch) and observer.subject() is inspectedAgent
        observer.resetPerspective()
      else
        inspectedAgent.watchMe()
      @update('agent') # force `isWatching` to recompute since observer perspective is external state
      return

    'watch-button-keydown': ({ original: event }) ->
      if isToggleKeydownEvent(event)
        @fire('watch-button-clicked')
        event.preventDefault()
        false

    'close-button-keydown': ({ original: event }) ->
      if isToggleKeydownEvent(event)
        @fire('closed-agent-monitor', {}, @get('agent'))
        event.preventDefault()
        false

    'monitor-keydown': ({ original: event }) ->
      if event.ctrlKey and event.key in ['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown']
        direction = if event.key in ['ArrowLeft', 'ArrowUp'] then -1 else 1
        @fire('switch-monitor', {}, direction)
        event.preventDefault()
        false
      else if event.ctrlKey and event.key is 'Home'
        @fire('switch-monitor', {}, 'first')
        event.preventDefault()
        false
      else if event.ctrlKey and event.key is 'End'
        @fire('switch-monitor', {}, 'last')
        event.preventDefault()
        false

    'agentVarField.agent-id-var-changed': (_, varName, newValue) ->
      currentAgent = @get('agent')
      newAgent = switch @get('agentType')
        when 'turtle'
          id = if varName is 'who' then parseInt(newValue) else currentAgent.id
          world.turtleManager.getTurtle(id)
        when 'patch'
          pxcor = if varName is 'pxcor' then parseInt(newValue) else currentAgent.pxcor
          pycor = if varName is 'pycor' then parseInt(newValue) else currentAgent.pycor
          world.getPatchAt(pxcor, pycor)
        when 'link'
          who1 = if varName is 'end1' then parseInt(newValue) else currentAgent.end1.id
          who2 = if varName is 'end2' then parseInt(newValue) else currentAgent.end2.id
          breedName = if varName is 'breed' then newValue else currentAgent.getBreedName()
          if world.breedManager.get(breedName)?
            world.linkManager.getLink(who1, who2, breedName)
          else
            # The breed name is invalid; asking the link manager for the link of an invalid breed will cause it to panic
            # We have to design around this.
            currentAgent
      # the agent could be Nobody
      if newAgent.id isnt -1
        @set('agent', newAgent)
      false
  }

  observe: {
    # While all other data about the agent is automatically updated once this Ractive
    # realizes that the agentRef has changed, the view is controlled by the ViewController,
    # so we need to interact with the ViewController to get a new view that reflects the
    # agent.
    'agent': {
      handler: (newValue, oldValue) ->
        if oldValue is newValue then return # we only care about when the identity changes (see Ractive API)
        if not newValue? then return        # guard against undefined agent during component teardown
        @_wasEverDead = false               # user explicitly navigated to a new agent; resume tracking
        @_syncAgentData(newValue)
        @get('replaceView')()
        return
      init: false # see `onrender`
    }
    'zoomLevel': {
      handler: (newZoomLevel) ->
        @get('zoomView')(newZoomLevel)
        return
      init: false # see `onrender`
    }
  }

  # (Number, Number) -> Array[Object]
  getContextMenuOptions: (clientX, clientY) ->
    viewWindow = @get('viewWindow')
    { left, top, bottom, right } = viewWindow.getBoundingClientRect()
    if left <= clientX <= right and top <= clientY <= bottom
      getClickedAgents(@get('viewController').getModel())(world, viewWindow, clientX, clientY)
        .map(agentToContextMenuOption(@get('setInspect')))
    else
      # The cursor is not actually inside the bounding box of the canvas (probably on the border)
      []

  # Focuses the first property control in the property grid, or the Watch button as a fallback.
  # () -> Unit
  focusFirstPropertyControl: ->
    target = @find('.inspection-agent-monitor-property-grid .inspection-input-container') ?
             @find('.inspection-agent-monitor-watch-button')
    target?.focus()
    return

  # Updates the 'viewModelAgent' and 'agentType' data to reflect the specified 'agent' data
  # (Agent) -> Unit
  _syncAgentData: (agent) ->
    [viewModelAgent, agentType] = getEquivalentAgent(@get('viewController').getModel())(agent)
    @set({ viewModelAgent, agentType })
    return

  template:
    """
    <div
      class="inspection-agent-monitor"
      on-mouseenter="['hover-agent-card', agent]"
      on-mouseleave="['unhover-agent-card', agent]"
      on-keydown="monitor-keydown"
    >
      {{>titleBar}}
      {{>viewSection}}
      {{>commandCenter}}
      {{>propertyGrid}}
    </div>
    """

  partials: {
    "titleBar": """
      <div class="inspection-agent-monitor-title-bar">
        <span class="title">{{agentName}}{{#if agentIsDead}} (dead){{/if}}</span>
        <div
          class="inspection-button"
          role="button"
          tabindex="0"
          on-click=["closed-agent-monitor", agent]
          on-keydown="close-button-keydown"
        >
          <img width=15 src="{{@global.NLWIcons.close}}"/>
        </div>
      </div>
    """

    "viewSection": """
      <div
        class="inspection-agent-monitor-view-container"
        on-contextmenu="show-context-menu"
      ></div>
      <div class="inspection-agent-monitor-view-controls">
        <div
          class="nlw-ui-button inspection-button inspection-agent-monitor-watch-button {{#if isWatching}}selected{{/if}}"
          role="button"
          tabindex="{{agentIsDead ? '-1' : '0'}}"
          aria-disabled="{{agentIsDead}}"
          on-click="watch-button-clicked"
          on-keydown="watch-button-keydown"
        >Watch</div>
        <input type="range" min=0 max=1 step=0.01 value="{{zoomLevel}}"/>
      </div>
    """

    "propertyGrid": """
      <div class="inspection-agent-monitor-property-grid">
        {{#each varNames as varName}}
          <agentVarField agent={{agent}} varName={{varName}} isReadOnly={{agentIsDead}}/>
        {{/each}}
      </div>
    """

    "commandCenter": """
      <div class="inspection-cmd-container" style="margin: 0;">
        <commandInput
          isReadOnly={{isEditing || agentIsDead}}
          source="agent-monitor"
          checkIsReporter={{checkIsReporter}}
          targetedAgentObj={{targetedAgentObj}}
          placeholderText="ask {{agentName}}"
          visiblePlaceholder="enter {{agentType}} commands"
        />
      </div>
    """
  }
})

export default RactiveAgentMonitor

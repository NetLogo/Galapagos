import RactiveAgentMonitor from "./agent-monitor.js"
import RactiveCommandInput from "./command-input.js"
import { Keybind, KeybindGroup } from '../accessibility/keybind.js'

{ arrayEquals } = tortoise_require('brazier/equals')
{ unique } = tortoise_require('brazier/array')
Turtle = tortoise_require('engine/core/turtle')
Patch = tortoise_require('engine/core/patch')
Link = tortoise_require('engine/core/link')

# Toggles whether a test item is present in an array. If it is, returns an array with all instances of the item removed;
# otherwise returns an array with the test item appended. Also returns whether a match was found.
# (Array[T], T, (T) -> (T) -> boolean) -> [Array[T], boolean]
togglePresence = (array, testItem, comparator) ->
  checkEqualToTest = comparator(testItem)
  matchFound = false
  filtered = array.filter((item) ->
    isEqual = checkEqualToTest(item)
    if isEqual then matchFound = true
    not isEqual
  )
  if not matchFound
    # Since we're toggling and `testItem` wasn't already present, add it.
    filtered.push(testItem)
  [filtered, matchFound]

# Given an agent, returns the keypath with respect to the 'stagedAgents' data to
# the array where that agent would go if it were staged.
# (Agent) -> string
getKeypathFor = (agent) ->
  switch
    when agent instanceof Turtle then ['turtles', agent.getBreedName()]
    when agent instanceof Patch then ['patches']
    when agent instanceof Link then ['links', agent.getBreedName()]

# Given an object and a array of keys, recursively accesses the object using those keys and returns the result.
# Consumes the array of keys up until continuing traversal is impossible. If a value along the path is undefined, and
# the default value is set, the value there will be set to the default value and then immediately returned.
# (any) -> any
traverseKeypath = (obj, keypath, defaultValue = undefined) ->
  x = obj
  while key = keypath.shift()
    if not x[key]? and defaultValue?
      x[key] = defaultValue
      return x[key]
    x = x[key]
  x

# (any) -> boolean
isAgent = (obj) -> obj instanceof Turtle or obj instanceof Patch or obj instanceof Link

# Treating an object as the root of a tree, prunes certain nodes of the tree
# (deleting an element of an array shifts the indices of the following elements,
# while deleting an element of an object simply removes the key-value pair). The
# provided tester function is given a pair of (node: any, keypath:
# Array[string]), and should return true if the node should be kept as-is
# (stopping deeper recursion), false if the node should be deleted, and null if
# the node should be recursively pruned. Returning null on a non-traversable
# value (i.e. a primitive) causes it to be deleted. After a node is recursively
# pruned, it is then tested again to see if it itself should be pruned.
#
# (any, (Array[string], any) -> boolean | null) -> Unit
pruneTree = (obj, tester, currentKeypath = []) ->
  for key, value of obj
    keypath = currentKeypath.concat([key])
    switch tester(value, keypath)
      when false then delete obj[key]
      when null
        if not value? or typeof value isnt 'object'
          delete obj[key]
        else # we know it must be a traversible object at this point
          pruneTree(value, tester, keypath)
          if tester(value, keypath) is false # don't delete if null or true
            delete obj[key]
      # tester returning true means skip the object without recursion
  if Array.isArray(obj)
    i = 0
    while i < obj.length
      if Object.hasOwn(obj, i)
        ++i
      else
        obj.splice(i, 1)
  return

RactiveInspectionPane = Ractive.extend({
  data: -> {
    # Props

    isEditing: undefined # boolean
    viewController: undefined # ViewController; from which the agent monitors take their ViewWindows
    checkIsReporter: undefined # (string) -> boolean

    # State

    pointToSelectEnabled: false # boolean

    updateTargetedAgentsInHistory: false # boolean; whether scrolling through history will also change what
    # agents are selected

    # NOTE: The stagedAgents structure and setInspect actions ('add', 'remove', 'unstage-all', 'clear-dead')
    # are intentionally retained for future reintroduction of the drag-to-select feature.
    # See the backup branch for the full drag-to-select implementation.

    # type StagedAgents = {
    #   turtles: Object<string, Array[Turtle]>,
    #   patches: Array[Patch],
    #   links: Object<string, Array[Link]>,
    # }
    # The `turtles` and `links` properties map breed names to lists of agents.
    stagedAgents: { 'turtles': {}, 'patches': [], 'links': {} } # StagedAgents

    ###
    type Selections = {
      selectedPaths: Array[CategoryPath] # should at least have the root path (`[]`) if none other is selected
      selectedAgents: Array[Agent] | null # null means to consider the categories as the main selections, not the agents
    }
    ###
    selections: { selectedPaths: [[]], selectedAgents: null }

    commandPlaceholderText: "" # string

    showCloseDropdown: false  # boolean; whether the close-button dropdown is open
    closeTargetIsDead: false  # boolean; false = close all monitors, true = close dead monitors only

    # inspectedAgents is passed as a prop from the parent skeleton so it persists when this tab is closed/reopened.
    # Array[Agent]; agents for which there is an opened agent monitor

  }

  computed: {
    # computing this value also sets the command placeholder text
    targetedAgentObj: {
      get: ->
        targetedAgents = @get('inspectedAgents')

        # check whether the selected agents are all of the same type
        # (i.e. turtles, patches, or links).
        selectedAgentTypes = unique(targetedAgents.map((agent) -> getKeypathFor(agent)[0]))
        if selectedAgentTypes.length is 1
          @set('commandPlaceholderText', "Input command for inspected #{selectedAgentTypes[0]}")
          { agentType: selectedAgentTypes[0], agents: targetedAgents }
        else
          # there are either no agents or the agents are not of the same type
          # (mix of turtles, patches, links) so just send the commands to the observer
          @set('commandPlaceholderText', "Input command for OBSERVER")
          { agentType: 'observer', agents: targetedAgents }

      set: (targetedAgentObj) ->
        if not @get('updateTargetedAgentsInHistory')
          # ignore the set operation and force the targeted agent obj to remain the same
          return

        # While we can't set the targetedAgentObj directly, we can attempt to put the inspection pane into a state such
        # that the getter would return something equivalent to the value passed to this setter.
        @set('inspectedAgents', targetedAgentObj.agents)
    }
  }

  observe: {
    'inspectedAgents': (agents) ->
      @fire('inspection-agents-changed', agents)

    'targetedAgentObj.agents': (newValue) ->
      @get('viewController').setHighlightedAgents(newValue)

    pointToSelectEnabled: (enabled) ->
      if enabled
        @_unsubscribePointToSelect = @get('viewController').registerMouseListeners(
          ({ clientX, clientY, event }) =>
            return if event?.button isnt 0 # only handle left-clicks
            # Suppress the document click handler (in handle-context-menu.coffee) from
            # hiding the context menu we're about to open.
            suppressClick = (e) -> e.stopImmediatePropagation()
            document.addEventListener('click', suppressClick, { capture: true, once: true })
            { pageX, pageY } = event
            @root.findComponent('contextMenu').reveal(@root.findComponent('viewWidget'), pageX, pageY, clientX, clientY)
          (->)  # no-op moveHandler
          (->)  # no-op upHandler
        )
      else
        @_unsubscribePointToSelect?()

    showCloseDropdown: (isOpen) ->
      if isOpen
        @_escHandler = (e) =>
          if e.key is 'Escape'
            @set('showCloseDropdown', false)
        document.addEventListener('keydown', @_escHandler)
      else if @_escHandler?
        document.removeEventListener('keydown', @_escHandler)
        @_escHandler = null
  }

  components: {
    agentMonitor: RactiveAgentMonitor,
    commandInput: RactiveCommandInput
  }

  on: {
    'agentMonitor.closed-agent-monitor': (_, agent) ->
      index = @get('inspectedAgents').indexOf(agent)
      if index >= 0
        @splice('inspectedAgents', index, 1)
      false

    'close-arrow-clicked': ->
      willOpen = not @get('showCloseDropdown')
      @toggle('showCloseDropdown')
      if willOpen
        setTimeout((=> @find('.inspection-split-button-dropdown-item')?.focus()), 0)

    'commandInput.command-input-tabbed': -> false # ignore and block event

    'agentMonitor.switch-monitor': (context, direction) ->
      agents = @get('inspectedAgents')
      agent = context.component.get('agent')
      currentIndex = agents.indexOf(agent)
      targetIndex = switch direction
        when 'first' then 0
        when 'last'  then agents.length - 1
        else currentIndex + direction
      if 0 <= targetIndex < agents.length
        monitors = @findAllComponents('agentMonitor')
        monitors[targetIndex]?.focusFirstPropertyControl()
      false

    unrender: ->
      @get('viewController').setHighlightedAgents([])
      if @_escHandler?
        document.removeEventListener('keydown', @_escHandler)
        @_escHandler = null
  }

  ### type SetInspectAction =
    { type: 'add' | 'remove', agents: Array[Agent], monitor: boolean }
    | { type: 'unstage-all', 'clear-dead' }
  ###
  # (SetInspectAction) -> Unit
  setInspect: (action) ->
    # prunes the `stagedAgents` tree, removing empty arrays (except for the
    # array for patches), and using the provided `agentTester` function to
    # determine whether to keep an agent
    #
    # (StagedAgents (Agent) -> boolean) -> Unit
    pruneAgents = (agentTester) =>
      stagedAgents = @get('stagedAgents')
      pruneTree(
        stagedAgents,
        (obj, keypath) =>
          if isAgent(obj)
            agentTester(obj) # either keep or delete the agent
          else if Array.isArray(obj) and obj.length is 0 and not arrayEquals(["patches"])(keypath)
            @selectCategory({ mode: 'remove', categoryPath: keypath })
            false # delete childless intermediate arrays except for the array for patches
          else
            null # recurse into all other nodes
      )
      @update('stagedAgents')

    switch action.type
      when 'add'
        stagedAgents = @get('stagedAgents')
        for agent in action.agents
          array = traverseKeypath(stagedAgents, getKeypathFor(agent), [])
          if not array.includes(agent)
            array.push(agent)
          if action.monitor and not @get('inspectedAgents').includes(agent)
            @toggleAgentMonitor(agent)
        @update('stagedAgents')
      when 'remove'
        stagedAgents = @get('stagedAgents')
        for agent in action.agents
          keypath = getKeypathFor(agent)
          arr = traverseKeypath(stagedAgents, keypath, [])
          index = arr.indexOf(agent) ? -1
          if index isnt -1
            arr.splice(index, 1)
          if action.monitor and @get('inspectedAgents').includes(agent)
            @toggleAgentMonitor(agent)
        @update('stagedAgents')
        # remove empty arrays
        pruneAgents((_) -> true)
        @unselectAgents(action.agents)
      when 'unstage-all'
        @set('selections.selectedAgents', null)
        pruneAgents((_) -> false)
      when 'clear-dead'
        @set('selections.selectedAgents', null)
        pruneAgents((agent) -> not agent.isDead())
        for agent in [@get('inspectedAgents')...]
          if agent.isDead()
            @toggleAgentMonitor(agent)

  # Selects the specified category. 'replace' mode removes all other selected
  # categories (single-clicking an item), while 'toggle' mode toggles whether
  # the item is selected (ctrl-clicking an item).
  # ({ mode: 'replace' | 'toggle' | 'remove', categoryPath: CategoryPath }) -> Unit
  selectCategory: ({ mode, categoryPath }) ->
    selectedPaths = switch mode
      when 'replace'
        [categoryPath]
      when 'toggle', 'remove'
        oldPaths = @get('selections.selectedPaths')
        [newPaths, matchFound] = togglePresence(oldPaths, categoryPath, arrayEquals)
        if newPaths.length is 0 then newPaths.push([])
        if mode is 'remove' and not matchFound
          oldPaths
        else
          newPaths

    ### @set('selection', { currentScreen: 'categories', selectedPaths }) ###
    # Ideally we'd want to use the concise code above instead of the kludgy bandaid below, but Ractive can't figure out
    # how to update the dependents of 'selection' in the correct order. If the inspection window is open, it will
    # complain that 'selection.currentAgent' is gone before it notices that, because 'selection.currentScreen' is
    # 'categories', it shouldn't even be rendered in the first place. So much for "Ractive runs updates based on
    # priority" (see https://ractive.js.org/concepts/#dependents), bunch of lying bastards. This complaining doesn't
    # cause any material issues, but it clogs up the console output. Therefore, we do a deep merge of the data, leaving
    # the keypath 'selection.currentAgent' valid even while 'selection.currentScreen' is 'categories'. However, the
    # option `deep: true` doesn't even work correctly either :P so we just manually do the deep merge.
    # --Andre C. (2023-08-23)
    # begin kludgy bandaid
    selections = @get('selections')
    selections.selectedPaths = selectedPaths
    selections.selectedAgents = null
    @update('selections')
    # end kludgy bandaid

  # Opens or closes an agent monitor showing detailed information and a mini
  # view of the specified agent.
  # (Agent) -> Unit
  toggleAgentMonitor: (agent) ->
    # use `ractive.unshift` and `ractive.splice` methods instead of the existing
    # `togglePresence` and `ractive.update` because the former two are smarter
    # about recognizing when elements have shifted rather than simply changed
    index = @get('inspectedAgents').indexOf(agent)
    if index is -1
      @unshift('inspectedAgents', agent)
      setTimeout(=>
        newMonitor = @find('.inspection-agent-monitor-container-inner > :first-child')
        newMonitor?.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'nearest' })
      , 200)
    else
      @splice('inspectedAgents', index, 1)

  closeMonitors: ->
    if @get('closeTargetIsDead')
      @setInspect({type: 'clear-dead'})
    else
      @set('inspectedAgents', [])

  toggleCloseTarget: ->
    @toggle('closeTargetIsDead')
    @set('showCloseDropdown', false)
    @closeMonitors()

  # (Array[Agent]) -> Unit
  unselectAgents: (agentsToUnselect) ->
    filtered = @get('selections.selectedAgents')?.filter((selected) -> not agentsToUnselect.includes(selected))
    @set('selections.selectedAgents', filtered)

  template: """
    <div class='netlogo-tab-content inspection-pane'>
      {{>commandCenter}}
      {{>agentMonitorsScreen}}
    </div>
  """

  # coffeelint: disable=max_line_length
  partials: {
    'commandCenter': """
      <div class="inspection-cmd-container">
        <button
          class="inspection-button inspection-point-to-select {{#if pointToSelectEnabled}}selected{{/if}}"
          title="Point to select: click an agent in the view to inspect it ({{#if pointToSelectEnabled}}on{{else}}off{{/if}})"
          on-click="@.toggle('pointToSelectEnabled')"
        >
          <img
            width=24
            src="{{@global.NLWIcons.pointToSelect}}"
          />
        </button>
        <div class="inspection-split-button">
          <button
            class="inspection-button inspection-split-button-main"
            title="{{#if closeTargetIsDead}}Close dead agent monitors{{else}}Remove all agent monitors{{/if}}"
            on-click="@.closeMonitors()"
          >
            <img width=24 src="{{@global.NLWIcons.close}}"/><span class="inspection-split-button-label">{{#if closeTargetIsDead}}close dead{{else}}close all{{/if}}</span>
          </button><button
            class="inspection-button inspection-split-button-arrow"
            title="More close options"
            on-click="close-arrow-clicked"
          >&#9660;</button>
          {{#if showCloseDropdown}}
          <div class="inspection-split-button-overlay" on-click="@.set('showCloseDropdown', false)"></div>
          <div class="inspection-split-button-dropdown">
            <button
              class="inspection-split-button-dropdown-item"
              on-click="@.toggleCloseTarget()"
            >{{#if closeTargetIsDead}}close all{{else}}close dead{{/if}}</button>
          </div>
          {{/if}}
        </div>
        <button
          class="inspection-button {{#if updateTargetedAgentsInHistory}}selected{{/if}}"
          title="Update targeted agents in history: ({{#if updateTargetedAgentsInHistory}}on{{else}}off{{/if}})"
          on-click="@.toggle('updateTargetedAgentsInHistory')"
        >
          <img
            width=24
            src="{{@global.NLWIcons.recallHistory}}"
          />
        </button>
        <commandInput
          isReadOnly={{isEditing}}
          source="inspection-pane"
          checkIsReporter={{checkIsReporter}}
          targetedAgentObj={{targetedAgentObj}}
          placeholderText={{commandPlaceholderText}}
        />
      </div>
    """

    'agentMonitorsScreen': """
      <div class="inspection-agent-monitor-container">
        <div class="inspection-agent-monitor-container-inner">
          {{#each inspectedAgents as agent}}
            <agentMonitor
              viewController={{viewController}}
              agent={{agent}}
              isEditing={{isEditing}}
              checkIsReporter={{checkIsReporter}}
              setInspect="{{@this.setInspect.bind(@this)}}"
            />
          {{else}}
            To open an agent monitor, right-click on the agent in the world view to open the inspection context menu, or use the `inspect` command on the agent through the
            Command Center.
          {{/each}}
        </div>
      </div>
    """
  }
  # coffeelint: enable=max_line_length

})

inspectionKeybindGroup = new KeybindGroup(
  "Agent Inspection Shortcuts",
  "Available when focus is inside an Agent Monitor.",
  [],
  [
    new Keybind(
      "monitor:navigate-previous",
      () -> {},
      ["ctrl+left", "ctrl+up"],
      { description: "Move focus to the previous agent monitor." },
      { bind: false }
    ),
    new Keybind(
      "monitor:navigate-next",
      () -> {},
      ["ctrl+right", "ctrl+down"],
      { description: "Move focus to the next agent monitor." },
      { bind: false }
    ),
    new Keybind(
      "monitor:navigate-first",
      () -> {},
      ["ctrl+home"],
      { description: "Move focus to the first agent monitor." },
      { bind: false }
    ),
    new Keybind(
      "monitor:navigate-last",
      () -> {},
      ["ctrl+end"],
      { description: "Move focus to the last agent monitor." },
      { bind: false }
    )
  ]
)

export { inspectionKeybindGroup }
export default RactiveInspectionPane

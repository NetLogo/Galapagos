RactiveHNWEditFormVariable = Ractive.extend({

  data: -> {
    newVariable: null # String
  }

  computed: {
    newVariableSet: ->
      newVariable = @get('newVariable')
      newVariable? and newVariable.trim() isnt ''
  }

  on: {

    'add-new-variable': ->
      newVariable = @get('newVariable')
      @set('newVariable', null)
      @fire('add-named-breed-var', newVariable.trim())
      return

    'use-new-var': (_, varName) ->
      @parent.fire('use-new-var', varName)
      return

  }

  template:
    """
    <div class="flex-row">
      <input type="text" value="{{newVariable}}" placeholder="new variable name"
             on-input="@this.set('newVariable', @node.value)" />
      <input type="button" on-click="add-new-variable" value="Add New Variable"
             disabled={{!newVariableSet}} />
    </div>
    """

})

export default RactiveHNWEditFormVariable

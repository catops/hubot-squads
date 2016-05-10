class Squad

  @robot = null

  @brain: ->
    throw new Error('robot is not set up') unless @robot
    @robot.brain

  @store: ->
    throw new Error('robot is not set up') unless @robot
    @robot.brain.data.squads or= {}

  @defaultName: ->
    '__default__'

  @all: ->
    squads = []
    for key, squadData of @store()
      continue if key is @defaultName()
      squads.push new Squad(squadData.name, squadData.members)
    squads

  @getDefault: (members = [])->
    @create(@defaultName(), members) unless @exists @defaultName()
    @get @defaultName()

  @count: ->
    Object.keys(@store()).length

  @get: (name)->
    return null unless @exists name
    squadData = @store()[name]
    new Squad(squadData.name, squadData.members)

  @getOrDefault: (squadName)->
    if squadName then @get(squadName) else @getDefault()

  @exists: (name)->
    name of @store()

  @create: (name, members = [])->
    return false if @exists name
    return false if /^squads?$/.test(name)
    @store()[name] =
      name: name
      members: members
    new Squad(name, members)

  constructor: (name, @members = [])->
    @name = name or Squad.defaultName()

  addMember: (member)->
    return false if member in @members
    @members.push member
    true

  removeMember: (member)->
    return false if member not in @members
    index = @members.indexOf(member)
    @members.splice(index, 1)
    true

  membersCount: ->
    @members.length

  clear: ->
    Squad.store()[@name].members = []
    @members = []

  destroy: ->
    delete Squad.store()[@name]

  isDefault: ->
    @name is Squad.defaultName()

  isValidUser: (user) ->
    return !!Squad.brain().userForName(user)

  label: ->
    "`#{@name}`"

module.exports = Squad

# Description:
#   Create a squad using hubot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_AUTH_ADMIN - A comma separate list of user IDs, requires https://github.com/hubot-scripts/hubot-auth
#
# Commands:
#   hubot create squad <squad_name> - create squad called <squad_name>
#   hubot (delete|remove) squad <squad_name> - delete squad called <squad_name>
#   hubot (list|show) squads - list all existing squads
#   hubot add (me|<user>) to squad <squad_name> - add me or <user> to squad
#   hubot remove (me|<user>) from squad <squad_name> - remove me or <user> from squad
#   hubot (list|show) squad <squad_name> - list the people in the squad
#   hubot (list|show) squad <squad_name> keys - lists the public SSH keys for everyone in the squad, requires `hubot-keys`
#   hubot (empty|clear) squad <squad_name> - clear everyone from squad
#
# Author:
#   contolini

Squad           = require './models/squad'
ResponseMessage = require './helpers/response_message'
UserNormalizer  = require './helpers/user_normalizer'

module.exports = (robot) ->
  robot.brain.data.squads or= {}
  Squad.robot = robot

  ##
  ## hubot create squad <squad_name> - create squad called <squad_name>
  ##
  robot.respond /create( new)? squad (\S*)/i, (msg) ->
    squadName = msg.match[2]
    if /^squads?$/.test(squadName)
      return msg.send ResponseMessage.squadBlacklisted squadName
    if squad = Squad.get squadName
      message = ResponseMessage.squadAlreadyExists squad
    else
      squad = Squad.create squadName
      message = ResponseMessage.squadCreated squad, robot.name
    msg.send message

  ##
  ## hubot remove squad <squad_name> - delete squad called <squad_name>
  ##
  robot.respond /(delete|remove) squad (\S*)$/i, (msg) ->
    squadName = msg.match[2]
    if robot.auth.isAdmin msg.envelope.user
      if squad = Squad.get squadName
        squad.destroy()
        message = ResponseMessage.squadDeleted(squad)
      else
        message = ResponseMessage.squadNotFound(squadName)
      msg.send message
    else
      msg.reply ResponseMessage.adminRequired()

  ##
  ## hubot add (me|<user>) to squad <squad_name> - add me or <user> to squad
  ##
  robot.respond /add (\S*) to squad (\S*)/i, (msg) ->
    squadName = msg.match[2]
    squad = Squad.getOrDefault(squadName)
    return msg.send ResponseMessage.squadNotFound(squadName) unless squad
    user = UserNormalizer.normalize(msg.message.user.name, msg.match[1])
    if !squad.isValidUser user
      return msg.send ResponseMessage.memberDoesntExist(user)
    if squad.addMember user
      message = ResponseMessage.memberAddedToSquad(user, squad)
    else
      message = ResponseMessage.memberAlreadyAddedToSquad(user, squad)
    msg.send message

  ##
  ## hubot remove (me|<user>) from squad <squad_name> - remove me or <user> from squad
  ##
  robot.respond /remove (\S*) (from|to) squad (\S*)/i, (msg) ->
    squadName = msg.match[3]
    squad = Squad.getOrDefault(squadName)
    return msg.send ResponseMessage.squadNotFound(squadName) unless squad
    user = UserNormalizer.normalize(msg.message.user.name, msg.match[1])
    isMemberRemoved = squad.removeMember user
    if isMemberRemoved
      message = ResponseMessage.memberRemovedFromSquad(user, squad)
    else
      message = ResponseMessage.memberAlreadyOutOfSquad(user, squad)
    msg.send message

  ##
  ## hubot list - list all existing squads
  ##
  robot.respond /(list|show)( all)? squads$/i, (msg) ->
    squads = Squad.all()
    msg.send ResponseMessage.listSquads(squads, robot.name)

  ##
  ## hubot (list|show) squad <squad_name> - list the people in the squad
  ##
  robot.respond /(list|show) squad (\S*)$/i, (msg) ->
    squadName = msg.match[2]
    squad = Squad.getOrDefault(squadName)
    message = if squad then ResponseMessage.listSquad(squad) else ResponseMessage.squadNotFound(squadName)
    msg.send message

  ##
  ## hubot (list|show) squad <squad_name> - list the keys of the people in the squad
  ##
  robot.respond /(list|show|get) squad (\S*) keys$/i, (msg) ->
    squadName = msg.match[2]
    squad = Squad.getOrDefault(squadName)
    message = if squad then ResponseMessage.listSquadKeys(squad, robot.name) else ResponseMessage.squadNotFound(squadName)
    msg.send message

  ##
  ## hubot (empty|clear) squad <squad_name> - clear squad list
  ##
  robot.respond /(empty|clear) squad (\S*)/i, (msg) ->
    if robot.auth.isAdmin msg.envelope.user
      squadName = msg.match[2]
      if squad = Squad.getOrDefault(squadName)
        squad.clear()
        message = ResponseMessage.squadCleared(squad)
      else
        message = ResponseMessage.squadNotFound(squadName)
      msg.send message
    else
      msg.reply ResponseMessage.adminRequired()

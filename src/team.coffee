# Description:
#   Create a team using hubot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_TEAM_ADMIN - A comma separate list of user names
#
# Commands:
#   hubot create team <team_name> - create team called <team_name>
#   hubot (delete|remove) team <team_name> - delete team called <team_name>
#   hubot (list|show) teams - list all existing teams
#   hubot add (me|<user>) to team <team_name> - add me or <user> to team
#   hubot remove (me|<user>) from team <team_name> - remove me or <user> from team
#   hubot (list|show) team <team_name> - list the people in the team
#   hubot (empty|clear) team <team_name> - clear everyone from team
#
# Author:
#   mihai

Team            = require './models/team'
ResponseMessage = require './helpers/response_message'
UserNormalizer  = require './helpers/user_normalizer'

module.exports = (robot) ->
  robot.brain.data.teams or= {}
  Team.robot = robot

  ##
  ## hubot teams create <team_name> - create team called <team_name>
  ##
  robot.respond /create( new)? team (\S*)/i, (msg) ->
    teamName = msg.match[2]
    if /^teams?$/.test(teamName)
      return msg.send ResponseMessage.teamBlacklisted teamName
    if team = Team.get teamName
      message = ResponseMessage.teamAlreadyExists team
    else
      team = Team.create teamName
      message = ResponseMessage.teamCreated team
    msg.send message

  ##
  ## hubot teams remove <team_name> - delete team called <team_name>
  ##
  robot.respond /(delete|remove) team (\S*)$/i, (msg) ->
    teamName = msg.match[2]
    if robot.auth.isAdmin msg.envelope.user
      if team = Team.get teamName
        team.destroy()
        message = ResponseMessage.teamDeleted(team)
      else
        message = ResponseMessage.teamNotFound(teamName)
      msg.send message
    else
      msg.reply ResponseMessage.adminRequired()

  ##
  ## hubot teams add (me|<user>) to <team_name> - add me or <user> to team
  ##
  robot.respond /add (\S*) to team (\S*)/i, (msg) ->
    teamName = msg.match[2]
    team = Team.getOrDefault(teamName)
    return msg.send ResponseMessage.teamNotFound(teamName) unless team
    user = UserNormalizer.normalize(msg.message.user.name, msg.match[1])
    if !team.isValidUser user
      return msg.send ResponseMessage.memberDoesntExist(user)
    if team.addMember user
      message = ResponseMessage.memberAddedToTeam(user, team)
    else
      message = ResponseMessage.memberAlreadyAddedToTeam(user, team)
    msg.send message

  ##
  ## hubot teams remove (me|<user>) from <team_name> - remove me or <user> from team
  ##
  robot.respond /remove (\S*) (from|to) team (\S*)/i, (msg) ->
    teamName = msg.match[3]
    team = Team.getOrDefault(teamName)
    return msg.send ResponseMessage.teamNotFound(teamName) unless team
    user = UserNormalizer.normalize(msg.message.user.name, msg.match[1])
    isMemberRemoved = team.removeMember user
    if isMemberRemoved
      message = ResponseMessage.memberRemovedFromTeam(user, team)
    else
      message = ResponseMessage.memberAlreadyOutOfTeam(user, team)
    msg.send message

  ##
  ## hubot teams list - list all existing teams
  ##
  robot.respond /(list|show)( all)? teams$/i, (msg) ->
    teams = Team.all()
    msg.send ResponseMessage.listTeams(teams)

  ##
  ## hubot teams (list|show) <team_name> - list the people in the team
  ##
  robot.respond /(list|show) team (\S*)$/i, (msg) ->
    teamName = msg.match[2]
    team = Team.getOrDefault(teamName)
    message = if team then ResponseMessage.listTeam(team) else ResponseMessage.teamNotFound(teamName)
    msg.send message

  ##
  ## hubot teams (empty|clear) <team_name> - clear team list
  ##
  robot.respond /(empty|clear) team (\S*)/i, (msg) ->
    if robot.auth.isAdmin msg.envelope.user
      teamName = msg.match[2]
      if team = Team.getOrDefault(teamName)
        team.clear()
        message = ResponseMessage.teamCleared(team)
      else
        message = ResponseMessage.teamNotFound(teamName)
      msg.send message
    else
      msg.reply ResponseMessage.adminRequired()

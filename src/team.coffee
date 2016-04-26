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
#   hubot teams create <team_name> - create team called <team_name>
#   hubot teams (delete|remove) <team_name> - delete team called <team_name>
#   hubot teams (list|show) teams - list all existing teams
#   hubot teams add (me|<user>) to <team_name> - add me or <user> to team
#   hubot teams remove (me|<user>) from <team_name> - remove me or <user> from team
#   hubot teams (list|show) <team_name> - list the people in the team
#   hubot teams (empty|clear) <team_name> - clear everyone from team
#
# Author:
#   mihai

Config          = require './models/config'
Team            = require './models/team'
ResponseMessage = require './helpers/response_message'
UserNormalizer  = require './helpers/user_normalizer'

module.exports = (robot) ->
  robot.brain.data.teams or= {}
  Team.robot = robot

  unless Config.adminList()
    robot.logger.warning 'HUBOT_TEAM_ADMIN environment variable not set'

  ##
  ## hubot teams create <team_name> - create team called <team_name>
  ##
  robot.respond /teams? create (\S*)/i, (msg) ->
    teamName = msg.match[1]
    if team = Team.get teamName
      message = ResponseMessage.teamAlreadyExists team
    else
      team = Team.create teamName
      message = ResponseMessage.teamCreated team
    msg.send message

  ##
  ## hubot teams remove <team_name> - delete team called <team_name>
  ##
  robot.respond /teams? (delete|remove) (\S*)/i, (msg) ->
    teamName = msg.match[2]
    if Config.isAdmin(msg.message.user.name)
      if team = Team.get teamName
        team.destroy()
        message = ResponseMessage.teamDeleted(team)
      else
        message = ResponseMessage.teamNotFound(teamName)
      msg.send message
    else
      msg.reply ResponseMessage.adminRequired()


  ##
  ## hubot teams list - list all existing teams
  ##
  robot.respond /teams? (list|show|all)( all)?( teams)?/i, (msg) ->
    teams = Team.all()
    msg.send ResponseMessage.listTeams(teams)

  ##
  ## hubot teams add (me|<user>) to <team_name> - add me or <user> to team
  ##
  robot.respond /teams add (\S*) to (\S*)/i, (msg) ->
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
  robot.respond /teams remove (\S*) (from|to) (\S*)/i, (msg) ->
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
  ## hubot teams (list|show) <team_name> - list the people in the team
  ##
  robot.respond /teams (list|show) (\S*)/i, (msg) ->
    teamName = msg.match[2]
    team = Team.getOrDefault(teamName)
    message = if team then ResponseMessage.listTeam(team) else ResponseMessage.teamNotFound(teamName)
    msg.send message

  ##
  ## hubot teams (empty|clear) <team_name> - clear team list
  ##
  robot.respond /teams (empty|clear) (\S*)/i, (msg) ->
    if Config.isAdmin(msg.message.user.name)
      teamName = msg.match[2]
      if team = Team.getOrDefault(teamName)
        team.clear()
        message = ResponseMessage.teamCleared(team)
      else
        message = ResponseMessage.teamNotFound(teamName)
      msg.send message
    else
      msg.reply ResponseMessage.adminRequired()

  ##
  ## hubot upgrade teams - upgrade team for the new structure
  ##
  robot.respond /upgrade teams$/i, (msg) ->
    teams = {}
    for index, team of robot.brain.data.teams
      if team instanceof Array
        teams[index] = new Team(index, team)
      else
        teams[index] = team

    robot.brain.data.teams = teams
    msg.send ResponseMessage.listTeams(Team.all())

class ResponseMessage

  teamCreated: (team)->
    "I created team #{team.label()}, add some people to it with `add [username] to team [team]`."

  teamAlreadyExists: (team)->
    "Team #{team.label()} already exists."

  teamBlacklisted: (team)->
    "Sorry, you can't create a team called 'team' or 'teams'."

  teamDeleted: (team)->
    "Team #{team.label()} removed."

  listTeams: (teams)->
    return 'No teams have been created. Create one with `create team [team]`.' if teams.length is 0
    message = "Teams:"

    for team in teams
      if team.membersCount() > 0
        message += "\n`#{team.name}` (#{team.membersCount()} total)"

        for user in team.members
          message += "\n- #{user}"
        message += "\n"
      else
        message += "\n`#{team.name}` (empty)"
    message

  adminRequired: -> "Sorry, only admins can perform this operation."

  memberAddedToTeam: (member, team)->
    count = team.membersCount() - 1
    message = "I added #{member} to team #{team.label()}."
    return message if count is 0
    singular_or_plural = if count is 1 then "other member is" else "others are"
    "#{message} #{count} #{singular_or_plural} in it."

  memberDoesntExist: (member)->
    "#{member} is not a valid user. Are you sure they have a chat account?"

  memberAlreadyAddedToTeam: (member, team)->
    "#{member} is already in team #{team.label()}."

  memberRemovedFromTeam: (member, team)->
    count = team.membersCount()
    message = "I removed #{member} from #{team.label()}."
    return message if count is 0
    "#{message} #{count} member remains."

  memberAlreadyOutOfTeam: (member, team)->
    "#{member} is not in team #{team.label()}."

  teamNotFound: (teamName)->
    "Team `#{teamName}` does not exist."

  listTeam: (team)->
    count = team.membersCount()
    if count is 0
      response = "There is no one in #{team.label()}."
    else
      position = 0
      response = "#{team.label()} (#{count} total):\n"
      for member in team.members
        position += 1
        response += "#{position}. #{member}\n"

    response

  teamCleared: (team)->
    "Team #{team.label()} has been emptied."

module.exports = new ResponseMessage

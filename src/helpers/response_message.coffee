class ResponseMessage

  squadCreated: (squad)->
    "I created squad #{squad.label()}, add some people to it with `add [username] to squad [squad]`."

  squadAlreadyExists: (squad)->
    "Squad #{squad.label()} already exists."

  squadBlacklisted: (squad)->
    "Sorry, you can't create a squad called 'squad' or 'squads'."

  squadDeleted: (squad)->
    "Squad #{squad.label()} removed."

  listSquads: (squads)->
    return 'No squads have been created. Create one with `create squad [squad]`.' if squads.length is 0
    message = "Squads:"

    for squad in squads
      if squad.membersCount() > 0
        message += "\n`#{squad.name}` (#{squad.membersCount()} total)"

        for user in squad.members
          message += "\n- #{user}"
        message += "\n"
      else
        message += "\n`#{squad.name}` (empty)"
    message

  adminRequired: -> "Sorry, only admins can perform this operation."

  memberAddedToSquad: (member, squad)->
    count = squad.membersCount() - 1
    message = "I added #{member} to squad #{squad.label()}."
    return message if count is 0
    singular_or_plural = if count is 1 then "other member is" else "others are"
    "#{message} #{count} #{singular_or_plural} in it."

  memberDoesntExist: (member)->
    "#{member} is not a valid user. Are you sure they have a chat account?"

  memberAlreadyAddedToSquad: (member, squad)->
    "#{member} is already in squad #{squad.label()}."

  memberRemovedFromSquad: (member, squad)->
    count = squad.membersCount()
    message = "I removed #{member} from #{squad.label()}."
    return message if count is 0
    "#{message} #{count} member remains."

  memberAlreadyOutOfSquad: (member, squad)->
    "#{member} is not in squad #{squad.label()}."

  squadNotFound: (squadName)->
    "Squad `#{squadName}` does not exist."

  listSquad: (squad)->
    count = squad.membersCount()
    if count is 0
      response = "There is no one in #{squad.label()}."
    else
      position = 0
      response = "#{squad.label()} (#{count} total):\n"
      for member in squad.members
        position += 1
        response += "#{position}. #{member}\n"

    response

  squadCleared: (squad)->
    "Squad #{squad.label()} has been emptied."

module.exports = new ResponseMessage

class UserNormalizer
  @normalizationEnabled: ->
    'HUBOT_SQUAD_NORMALIZE_USERNAMES' of process.env

  @normalize: (username, userInput)->
    if userInput and userInput.toLocaleLowerCase() isnt 'me'
      username = userInput
    if @normalizationEnabled()
      '@' + username.replace /@*/g, ''
    else
      username

module.exports = UserNormalizer

chai        = require 'chai'
sinon       = require 'sinon'
expect      = chai.expect
helper      = require 'hubot-mock-adapter-helper'
TextMessage = require('hubot/src/message').TextMessage
Team        = require '../src/models/team'

chai.use require 'sinon-chai'

class Helper
  constructor: (@robot, @adapter, @user)->

  replyMessageWithNoAdmin: (done, message, callback)->
    @sendMessageHubot({name: 'noadmin'}, message, callback, done, 'reply')

  replyMessage: (done, message, callback)->
    @sendMessageHubot(@user, message, callback, done, 'reply')

  sendMessageWithNoAdmin: (done,  message, callback)->
    @sendMessageHubot({name: 'noadmin'}, message, callback, done, 'send')

  sendMessage: (done, message, callback)->
    @sendMessageHubot(@user, message, callback, done, 'send')

  sendMessageHubot: (user, message, callback, done, event)->
    @adapter.on event, (envelop, string) ->
      try
        callback(string)
        done()
      catch e
        done e
    @adapter.receive new TextMessage(user, message)


describe 'hubot-team', ->
  {robot, user, adapter} = {}
  messageHelper = null

  beforeEach (done)->
    helper.setupRobot (ret) ->
      process.setMaxListeners(0)
      {robot, user, adapter} = ret
      messageHelper = new Helper(robot, adapter, user)
      process.env.HUBOT_TEAM_ADMIN = user['name']
      messageHelper.robot.auth = hasRole: ->
        true
      do done

  afterEach ->
    robot.shutdown()

  beforeEach ->
    require('../src/team')(robot)

  describe 'create a team', ->
    it 'shows a message when team is created successfully', (done)->
      messageHelper.sendMessage(done, 'hubot create team soccer', (result)->
        expect(result[0]).to.equal('`soccer` team created, add some people to it')
      )

    describe 'failure', ->
      it 'shows a message when team is already been created', (done)->
        Team.create('soccer')
        messageHelper.sendMessage(done, 'hubot create team soccer', (result)->
          expect(result[0]).to.equal('`soccer` team already exists')
        )

  describe '(delete|remove) a team', ->
    it 'shows a message when team does not exist', (done) ->
      messageHelper.sendMessage(done, 'hubot delete team soccer', (result)->
        expect(result[0]).to.equal('`soccer` team does not exist'))

    it 'shows a message when team is removed successfully', (done) ->
      Team.create('soccer')
      messageHelper.sendMessage(done, 'hubot delete team soccer', (result)->
        expect(result[0]).to.equal('`soccer` team removed'))

    it 'shows a message if an admin is required', (done) ->
      Team.create('soccer')
      messageHelper.robot.auth = hasRole: ->
        false
      messageHelper.replyMessageWithNoAdmin(done, 'hubot delete team soccer', (result)->
        expect(result[0]).to.equal('Sorry, only admins can perform this operation'))

  describe 'list all teams', ->
    it 'shows the teams without members', (done)->
      Team.create('soccer')
      messageHelper.sendMessage(done, 'hubot list all teams', (result)->
        expect(result[0]).to.equal('Teams:\n`soccer` (empty)'))

    it 'shows the teams with members', (done)->
      Team.create('soccer', ['peter'])
      messageHelper.sendMessage(done, 'hubot list all teams', (result)->
        expect(result[0]).to.equal('Teams:\n`soccer` (1 total)\n- peter'))

    it 'shows no team created message', (done)->
      messageHelper.sendMessage(done, 'hubot list all teams', (result)->
        expect(result[0]).to.equal('No team was created so far'))

  describe 'teamName? team add (me|user)', ->

    it 'shows a message when team does not exist', (done)->
      messageHelper.sendMessage(done, 'hubot add peter to team soccer', (result)->
        expect(result[0]).to.equal('`soccer` team does not exist'))

    it 'shows a message when member is already in the team', (done)->
      robot.brain.data.users = [{ id: '1234', name: 'peter' }]
      Team.create('soccer', ['peter'])
      messageHelper.sendMessage(done, 'hubot add peter to team soccer', (result)->
        expect(result[0]).to.equal('peter already in the `soccer` team'))

    it 'shows a message when user is new in team', (done)->
      robot.brain.data.users = [{ id: '1234', name: 'peter' }]
      Team.create('soccer')
      messageHelper.sendMessage(done, 'hubot add peter to team soccer', (result)->
        expect(result[0]).to.equal('peter added to the `soccer` team'))

    it 'shows a message when user does not exist', (done)->
      Team.create('soccer')
      messageHelper.sendMessage(done, 'hubot add peter to team soccer', (result)->
        expect(result[0]).to.equal('peter is not a valid user. Are you sure they have a chat account?'))

  describe 'teamName? team remove member', ->
    it 'shows a message when user does not exist in team', (done)->
      Team.create('soccer')
      messageHelper.sendMessage(done, 'hubot remove peter from team soccer', (result)->
        expect(result[0]).to.equal('peter already out of the `soccer` team'))

    it 'shows a message when user exists in team', (done)->
      Team.create('soccer', ['peter', '@james'])
      messageHelper.sendMessage(done, 'hubot remove peter from team soccer', (result)->
        expect(result[0]).to.equal('peter removed from the `soccer` team, 1 remaining'))

  describe 'teamName? team list|show', ->
    it 'shows a message listing the members in a team', (done)->
      Team.create('soccer', ['mocha', 'peter'])
      messageHelper.sendMessage(done, 'hubot list team soccer', (result)->
        expect(result[0]).to.equal('`soccer` team (2 total):\n1. mocha\n2. peter\n'))

  describe 'teamName? team clear|empty', ->
    it 'shows a message when members have been removed', (done)->
      Team.create('soccer', ['mocha', 'peter'])

      messageHelper.sendMessage(done, 'hubot empty team soccer', (result)->
        expect(result[0]).to.equal('`soccer` team list cleared'))

chai        = require 'chai'
sinon       = require 'sinon'
expect      = chai.expect
helper      = require 'hubot-mock-adapter-helper'
TextMessage = require('hubot/src/message').TextMessage
Squad        = require '../src/models/squad'

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


describe 'hubot-squad', ->
  {robot, user, adapter} = {}
  messageHelper = null

  beforeEach (done)->
    helper.setupRobot (ret) ->
      process.setMaxListeners(0)
      {robot, user, adapter} = ret
      messageHelper = new Helper(robot, adapter, user)
      process.env.HUBOT_AUTH_ADMIN = user['id']
      messageHelper.robot.auth = isAdmin: ->
        return process.env.HUBOT_AUTH_ADMIN.split(',').indexOf(user['id']) > -1
      do done

  afterEach ->
    robot.shutdown()

  beforeEach ->
    require('../src/squads')(robot)

  describe 'create a squad', ->
    it 'shows a message when squad is created successfully', (done)->
      messageHelper.sendMessage(done, 'hubot create squad soccer', (result)->
        expect(result[0]).to.equal('I created squad `soccer`, add some people to it with `hubot add [username] to squad [squad]`.')
      )

    describe 'failure', ->
      it 'shows a message when squad is already been created', (done)->
        Squad.create('soccer')
        messageHelper.sendMessage(done, 'hubot create squad soccer', (result)->
          expect(result[0]).to.equal('Squad `soccer` already exists.')
        )

  describe '(delete|remove) a squad', ->
    it 'shows a message when squad does not exist', (done) ->
      messageHelper.sendMessage(done, 'hubot delete squad soccer', (result)->
        expect(result[0]).to.equal('Squad `soccer` does not exist.'))

    it 'shows a message when squad is removed successfully', (done) ->
      Squad.create('soccer')
      messageHelper.sendMessage(done, 'hubot delete squad soccer', (result)->
        expect(result[0]).to.equal('Squad `soccer` removed.'))

    it 'shows a message if an admin is required', (done) ->
      process.env.HUBOT_AUTH_ADMIN = []
      Squad.create('soccer')
      messageHelper.replyMessageWithNoAdmin(done, 'hubot delete squad soccer', (result)->
        expect(result[0]).to.equal('Sorry, only admins can perform this operation.'))

  describe 'list all squads', ->
    it 'shows the squads without members', (done)->
      Squad.create('soccer')
      messageHelper.sendMessage(done, 'hubot list all squads', (result)->
        expect(result[0]).to.equal('Squads:\n`soccer` (empty)'))

    it 'shows the squads with members', (done)->
      Squad.create('soccer', ['peter'])
      messageHelper.sendMessage(done, 'hubot list all squads', (result)->
        expect(result[0]).to.equal('Squads:\n`soccer` (1 total)\n- peter\n'))

    it 'shows no squad created message', (done)->
      messageHelper.sendMessage(done, 'hubot list all squads', (result)->
        expect(result[0]).to.equal('No squads have been created. Create one with `hubot create squad [squad]`.'))

  describe 'squadName? squad add (me|user)', ->

    it 'shows a message when squad does not exist', (done)->
      messageHelper.sendMessage(done, 'hubot add peter to squad soccer', (result)->
        expect(result[0]).to.equal('Squad `soccer` does not exist.'))

    it 'shows a message when member is already in the squad', (done)->
      robot.brain.data.users = [{ id: '1234', name: 'peter' }]
      Squad.create('soccer', ['peter'])
      messageHelper.sendMessage(done, 'hubot add peter to squad soccer', (result)->
        expect(result[0]).to.equal('peter is already in squad `soccer`.'))

    it 'shows a message when user is new in squad', (done)->
      robot.brain.data.users = [{ id: '1234', name: 'peter' }]
      Squad.create('soccer')
      messageHelper.sendMessage(done, 'hubot add peter to squad soccer', (result)->
        expect(result[0]).to.equal('I added peter to squad `soccer`.'))

    it 'shows a message when user does not exist', (done)->
      Squad.create('soccer')
      messageHelper.sendMessage(done, 'hubot add peter to squad soccer', (result)->
        expect(result[0]).to.equal('peter is not a valid user. Are you sure they have a chat account?'))

  describe 'squadName? squad remove member', ->
    it 'shows a message when user does not exist in squad', (done)->
      Squad.create('soccer')
      messageHelper.sendMessage(done, 'hubot remove peter from squad soccer', (result)->
        expect(result[0]).to.equal('peter is not in squad `soccer`.'))

    it 'shows a message when user exists in squad', (done)->
      Squad.create('soccer', ['peter', '@james'])
      messageHelper.sendMessage(done, 'hubot remove peter from squad soccer', (result)->
        expect(result[0]).to.equal('I removed peter from `soccer`. 1 member remains.'))

  describe 'squadName? squad list|show', ->
    it 'shows a message listing the members in a squad', (done)->
      Squad.create('soccer', ['mocha', 'peter'])
      messageHelper.sendMessage(done, 'hubot list squad soccer', (result)->
        expect(result[0]).to.equal('`soccer` (2 total):\n1. mocha\n2. peter\n'))

  describe 'squadName? squad list|show keys', ->
    it 'shows a message telling the user to install `hubot-keys`', (done)->
      Squad.create('soccer', ['mocha', 'peter'])
      messageHelper.sendMessage(done, 'hubot list squad soccer keys', (result)->
        expect(result[0]).to.equal("To manage members' public keys, please install the `hubot-keys` plugin."))

  describe 'squadName? squad clear|empty', ->
    it 'shows a message when members have been removed', (done)->
      Squad.create('soccer', ['mocha', 'peter'])

      messageHelper.sendMessage(done, 'hubot empty squad soccer', (result)->
        expect(result[0]).to.equal('Squad `soccer` has been emptied.'))

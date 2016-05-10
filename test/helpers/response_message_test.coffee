expect          = require('chai').expect
responseMessage = require '../../src/helpers/response_message'
Squad           = require '../../src/models/squad'

describe 'ResponseMessage', ->
  beforeEach ->
    Squad.robot = {brain: {data: {}}}

  describe '#squadCreated', ->
    it 'returns the message', ->
      squad = new Squad('squad1')
      expect(responseMessage.squadCreated(squad)).to.eql('I created squad `squad1`, add some people to it with `add [username] to squad [squad]`.')

  describe '#squadAlreadyExists', ->
    it 'returns the message', ->
      squad = Squad.create('squad1')
      expect(responseMessage.squadAlreadyExists(squad)).to.eql('Squad `squad1` already exists.')

  describe '#squadDeleted', ->
    it 'returns the message', ->
      squad = Squad.create('squad1')
      expect(responseMessage.squadDeleted(squad)).to.eql('Squad `squad1` removed.')

  describe '#listSquads', ->
    describe 'squads with members', ->
      it 'includes members and total', ->
        Squad.create('squad1', ['@member1', '@member2'])
        squads = Squad.all()
        expected = 'Squads:\n`squad1` (2 total)\n- @member1\n- @member2\n'
        expect(responseMessage.listSquads(squads)).to.eql(expected)

    describe 'without members', ->
      it 'does not include members', ->
        Squad.create('squad1')
        Squad.create('squad2')
        squads = Squad.all()
        expected = 'Squads:\n`squad1` (empty)\n`squad2` (empty)'
        expect(responseMessage.listSquads(squads)).to.eql(expected)

  describe '#adminRequired', ->
    it 'returns the message', ->
      expect(responseMessage.adminRequired()).to.eql('Sorry, only admins can perform this operation.')

  describe '#memberAddedToSquad', ->
    describe 'there is no members in the squad', ->
      it 'returns the message', ->
        squad = new Squad('squad1', ['member1'])
        expect(responseMessage.memberAddedToSquad('member1', squad)).to.eql('I added member1 to squad `squad1`.')

    describe 'there is one member in the squad', ->
      it 'returns the message', ->
        squad = new Squad('squad1', ['member1', 'member2'])
        expect(responseMessage.memberAddedToSquad('member2', squad)).to.eql('I added member2 to squad `squad1`. 1 other member is in it.')

    describe 'there are two members in the squad', ->
      it 'returns the message', ->
        squad = new Squad('squad1', ['member1', 'member2', 'member3'])
        expect(responseMessage.memberAddedToSquad('member3', squad)).to.eql('I added member3 to squad `squad1`. 2 others are in it.')

  describe '#memberAlreadyAddedToSquad', ->
    it 'returns the message', ->
      squad = new Squad('squad1')
      expect(responseMessage.memberAlreadyAddedToSquad('member1', squad)).to.eql('member1 is already in squad `squad1`.')

  describe '#memberRemovedFromSquad', ->
    describe 'there is one member', ->
      it 'returns the message', ->
        squad = new Squad('squad1', [])
        expect(responseMessage.memberRemovedFromSquad('member1', squad)).to.eql('I removed member1 from `squad1`.')

    describe 'there are some members', ->
      it 'returns the message', ->
        squad = new Squad('squad1', ['member1'])
        expect(responseMessage.memberRemovedFromSquad('member2', squad)).to.eql('I removed member2 from `squad1`. 1 member remains.')

  describe '#memberAlreadyOutOfSquad', ->
    it 'returns the message', ->
      squad = new Squad('squad1')
      expect(responseMessage.memberAlreadyOutOfSquad('member1', squad)).to.eql('member1 is not in squad `squad1`.')

  describe '#squadNotFound', ->
    it 'returns the message', ->
      expect(responseMessage.squadNotFound('squad1')).to.eql('Squad `squad1` does not exist.')

  describe '#listSquad', ->
    describe 'with members', ->
      it 'returns the message', ->
        squad = Squad.create('squad1', ['@member2', '@member2'])
        expected = '`squad1` (2 total):\n1. @member2\n2. @member2\n'
        expect(responseMessage.listSquad(squad)).to.eql(expected)

    describe 'without members', ->
      it 'returns the message', ->
        squad = Squad.create('squad1')
        expected = 'There is no one in `squad1`.'
        expect(responseMessage.listSquad(squad)).to.eql(expected)

  describe '#squadCleared', ->
    it 'returns the message', ->
      squad = Squad.create('soccer')
      expect(responseMessage.squadCleared(squad)).to.eql("Squad `soccer` has been emptied.")

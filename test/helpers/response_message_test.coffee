expect          = require('chai').expect
responseMessage = require '../../src/helpers/response_message'
Team            = require '../../src/models/team'

describe 'ResponseMessage', ->
  beforeEach ->
    Team.robot = {brain: {data: {}}}

  describe '#teamCreated', ->
    it 'returns the message', ->
      team = new Team('team1')
      expect(responseMessage.teamCreated(team)).to.eql('I created team `team1`, add some people to it with `add [username] to team [team]`.')

  describe '#teamAlreadyExists', ->
    it 'returns the message', ->
      team = Team.create('team1')
      expect(responseMessage.teamAlreadyExists(team)).to.eql('Team `team1` already exists.')

  describe '#teamDeleted', ->
    it 'returns the message', ->
      team = Team.create('team1')
      expect(responseMessage.teamDeleted(team)).to.eql('Team `team1` removed.')

  describe '#listTeams', ->
    describe 'teams with members', ->
      it 'includes members and total', ->
        Team.create('team1', ['@member1', '@member2'])
        teams = Team.all()
        expected = 'Teams:\n`team1` (2 total)\n- @member1\n- @member2\n'
        expect(responseMessage.listTeams(teams)).to.eql(expected)

    describe 'without members', ->
      it 'does not include members', ->
        Team.create('team1')
        Team.create('team2')
        teams = Team.all()
        expected = 'Teams:\n`team1` (empty)\n`team2` (empty)'
        expect(responseMessage.listTeams(teams)).to.eql(expected)

  describe '#adminRequired', ->
    it 'returns the message', ->
      expect(responseMessage.adminRequired()).to.eql('Sorry, only admins can perform this operation.')

  describe '#memberAddedToTeam', ->
    describe 'there is no members in the team', ->
      it 'returns the message', ->
        team = new Team('team1', ['member1'])
        expect(responseMessage.memberAddedToTeam('member1', team)).to.eql('I added member1 to team `team1`.')

    describe 'there is one member in the team', ->
      it 'returns the message', ->
        team = new Team('team1', ['member1', 'member2'])
        expect(responseMessage.memberAddedToTeam('member2', team)).to.eql('I added member2 to team `team1`. 1 other member is in it.')

    describe 'there are two members in the team', ->
      it 'returns the message', ->
        team = new Team('team1', ['member1', 'member2', 'member3'])
        expect(responseMessage.memberAddedToTeam('member3', team)).to.eql('I added member3 to team `team1`. 2 others are in it.')

  describe '#memberAlreadyAddedToTeam', ->
    it 'returns the message', ->
      team = new Team('team1')
      expect(responseMessage.memberAlreadyAddedToTeam('member1', team)).to.eql('member1 is already in team `team1`.')

  describe '#memberRemovedFromTeam', ->
    describe 'there is one member', ->
      it 'returns the message', ->
        team = new Team('team1', [])
        expect(responseMessage.memberRemovedFromTeam('member1', team)).to.eql('I removed member1 from `team1`.')

    describe 'there are some members', ->
      it 'returns the message', ->
        team = new Team('team1', ['member1'])
        expect(responseMessage.memberRemovedFromTeam('member2', team)).to.eql('I removed member2 from `team1`. 1 member remains.')

  describe '#memberAlreadyOutOfTeam', ->
    it 'returns the message', ->
      team = new Team('team1')
      expect(responseMessage.memberAlreadyOutOfTeam('member1', team)).to.eql('member1 is not in team `team1`.')

  describe '#teamNotFound', ->
    it 'returns the message', ->
      expect(responseMessage.teamNotFound('team1')).to.eql('Team `team1` does not exist.')

  describe '#listTeam', ->
    describe 'with members', ->
      it 'returns the message', ->
        team = Team.create('team1', ['@member2', '@member2'])
        expected = '`team1` (2 total):\n1. @member2\n2. @member2\n'
        expect(responseMessage.listTeam(team)).to.eql(expected)

    describe 'without members', ->
      it 'returns the message', ->
        team = Team.create('team1')
        expected = 'There is no one in `team1`.'
        expect(responseMessage.listTeam(team)).to.eql(expected)

  describe '#teamCleared', ->
    it 'returns the message', ->
      team = Team.create('soccer')
      expect(responseMessage.teamCleared(team)).to.eql("Team `soccer` has been emptied.")

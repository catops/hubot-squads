expect = require('chai').expect
Squad   = require '../../src/models/squad'

describe 'Squad', ->
  beforeEach ->
    Squad.robot = {brain: {data: {}}}

  describe 'class methods', ->
    describe '.store', ->
      it 'gets the store', ->
        squads = {test: {name: 'test', members: []}}
        Squad.robot.brain.data.squads = squads
        expect(Squad.store()).to.eql(squads)

      describe 'storage is not initialized', ->
        it 'initializes', ->
          expect(Squad.store()).to.eql({})

      describe 'robot is not defined', ->
        it 'throws an error', ->
          Squad.robot = null
          expect(Squad.store).to.throw(/robot is not set up/)

    describe '.defaultName', ->
      it 'return the default squad name', ->
        expect(Squad.defaultName()).to.eql('__default__')

    describe '.all', ->
      it 'returns an array with the squads', ->
        Squad.create('squad1')
        squads = Squad.all()
        expect(squads[0].name).to.eql('squad1')

      describe 'store contains the default squad', ->
        it 'excludes the default squad', ->
          Squad.create('squad1')
          Squad.getDefault()
          squads = Squad.all()
          expect(squads.length).to.eql(1)

      describe 'store is empty', ->
        it 'returns an empty array', ->
          expect(Squad.all()).to.eql([])

    describe '.getDefault', ->
      describe 'default squad already exist', ->
        it 'returns the default squad', ->
          expect(Squad.getDefault().isDefault()).to.be.true

      describe 'default squad does not exist', ->
        it 'saves the default squad in the store', ->
          expect(Squad.store()).to.not.include.keys('__default__')
          Squad.getDefault()
          expect(Squad.store()).to.include.keys('__default__')

    describe '.count', ->
      it 'returns the exact count', ->
        Squad.store()['squad1'] =
          name: 'squad1'
          members: []
        expect(Squad.count()).to.eql(1)

      describe 'store is empty', ->
        it 'returns zero', ->
          expect(Squad.count()).to.eql(0)

    describe '.get', ->
      it 'returns the matching squad', ->
        Squad.store()['squad1'] =
          name: 'squad1'
          members: ['member1']
        squad = Squad.get('squad1')
        expect(squad.name).to.eql('squad1')
        expect(squad.members).to.eql(['member1'])

      describe 'store has no matching data', ->
        it 'returns null', ->
          expect(Squad.get('squad1')).to.be.null

      describe 'name not given', ->
        it 'returns null', ->
          expect(Squad.get()).to.be.null

    describe '.getOrDefault', ->
      describe 'squadName is given', ->
        it 'finds a squad', ->
          Squad.create 'squad1'
          squad = Squad.getOrDefault('squad1')
          expect(squad.name).to.eql('squad1')

        describe 'store has no matching data', ->
          it 'returns null', ->
            expect(Squad.getOrDefault('squad1')).to.be.null

      describe 'squadName is not given', ->
        it 'returns the default squad', ->
          expect(Squad.getOrDefault().isDefault()).to.be.true

    describe '.exists', ->
      describe 'store has matching data', ->
        it 'returns true', ->
          Squad.store()['squad1'] =
            name: 'squad1'
            members: []
          expect(Squad.exists('squad1')).to.be.true

      describe 'store has no matching data', ->
        it 'returns false', ->
          expect(Squad.exists('squad1')).to.be.false

    describe '.create', ->
      it 'saves the squad in the store', ->
        Squad.create('squad1')
        expect(Squad.store()).to.include.keys('squad1')

      it 'returns a new squad', ->
        squad = Squad.create('squad1')
        expect(squad.name).to.eql('squad1')

      describe 'store contains a squad with the same name', ->
        it 'returns false', ->
          Squad.store()['squad1'] =
          name: 'squad1'
          members: []
          expect(Squad.create('squad1')).to.be.false

  describe 'instance methods', ->
    describe '#constructor', ->
      it 'stores the name', ->
        squad = new Squad('squad1', [])
        expect(squad.name).to.eql('squad1')

      it 'stores the members', ->
        squad = new Squad('squad1', [])
        expect(squad.members).to.eql([])

      describe 'name is not given', ->
        it 'assigns the default squad name', ->
          squad = new Squad()
          expect(squad.name).to.eql('__default__')

      describe 'members is not given', ->
        it 'assigns an empty array', ->
          squad = new Squad()
          expect(squad.members).to.eql([])

    describe '#addMember', ->
      squad = null

      beforeEach ->
        squad = Squad.create('squad1')
        squad.addMember('@member1')

      it 'adds the member to the local collection', ->
        expect(squad.members).to.include('@member1')

      it 'adds 1 member to the collection', ->
        expect(squad.members).to.have.length(1)

      it 'adds the member to the store', ->
        members = Squad.store()['squad1'].members
        expect(members).to.include('@member1')

      it 'returns true', ->
        expect(squad.addMember('@member2')).to.be.true

      describe 'member already exists', ->
        it 'returns false', ->
          expect(squad.addMember('@member1')).to.be.false

    describe '#removeMember', ->
      it 'removes the member from the local collection', ->
        squad = Squad.create('squad1', ['member1'])
        squad.removeMember('member1')
        expect(squad.members).to.eql([])

      it 'removes the member from the store', ->
        squad = Squad.create('squad1', ['member1'])
        squad.removeMember('member1')
        expect(Squad.store()['squad1'].members).to.eql([])

      describe 'member does not exist', ->
        it 'returns false', ->
          squad = Squad.create('squad1')
          expect(squad.removeMember('member1')).to.be.false

    describe '#membersCount', ->
      it 'returns the quantity of members in the squad', ->
        squad = Squad.create('squad1', ['@member1', '@member2'])
        expect(squad.membersCount()).to.eql(2)

    describe '#clear', ->
      squad = null
      beforeEach ->
        squad = Squad.create('squad1', ['@member1'])

      it 'removes all members from the local collection', ->
        squad.clear()
        expect(squad.members).to.eql([])

      it 'removes all members from the store', ->
        squad.clear()
        expect(Squad.store()['squad1'].members).to.eql([])

    describe '#destroy', ->
      squad = null
      beforeEach ->
        squad = Squad.create('squad1')

      it 'removes the squad from the store', ->
        squad.destroy()
        expect(Squad.store()).to.not.include.keys('squad1')

    describe '#isDefault', ->
      describe 'name is the default squad label', ->
        it 'returns true', ->
          squad = new Squad()
          expect(squad.isDefault()).to.be.true

      describe 'name is not the default squad label', ->
        it 'returns false', ->
          squad = new Squad('squad1')
          expect(squad.isDefault()).to.be.false

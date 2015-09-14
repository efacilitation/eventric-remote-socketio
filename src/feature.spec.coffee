describe 'SocketIO remote scenario', ->
  eventric = null
  socketIORemoteEndpoint = null
  socketIORemoteClient = null
  socketServer = null
  socketClient = null

  before (done) ->
    eventric = require 'eventric'

    socketServer = require('socket.io')()
    socketServer.listen 3000
    socketIORemoteEndpoint = require './endpoint'
    socketIORemoteEndpoint.initialize ioInstance: socketServer, ->
      eventric.addRemoteEndpoint socketIORemoteEndpoint
      socketClient = require('socket.io-client')('http://localhost:3000')
      socketClient.on 'connect', ->
        socketIORemoteClient = require 'eventric-remote-socketio-client'
        socketIORemoteClient.initialize ioClientInstance: socketClient
        .then done
        .catch done


  after ->
    socketIORemoteEndpoint.close()
    socketIORemoteClient.disconnect()
    require._cache = {}


  describe 'creating an example context and adding a socketio remote endpoint', ->
    exampleRemote = null
    socketIORemoteClient = null
    doSomethingStub = null
    createSomethingStub = null
    modifySomethingStub = null

    beforeEach ->
      exampleContext = require './example_context'
      doSomethingStub = sinon.stub()
      createSomethingStub = sinon.stub()
      modifySomethingStub = sinon.stub()

      exampleContext.addCommandHandlers
        CommandWhichRejects: ->
          error = throw new Error 'The error message'
        DoSomething: doSomethingStub

      exampleContext.initialize()
      .then ->
        exampleRemote = eventric.remote 'Example'
        exampleRemote.setClient socketIORemoteClient


    it 'should be possible to access the original error message of an error from a command handler', ->
      exampleRemote.command 'CommandWhichRejects'
      .catch (error) ->
        expect(error instanceof Error).to.be.true
        expect(error.message).to.contain 'The error message'
        expect(error.originalErrorMessage).to.equal 'The error message'


    it 'should be possible to receive and execute commands', ->
      exampleRemote.command 'CreateSomething'
      .then (aggregateId) ->
        exampleRemote.command 'DoSomething', aggregateId: aggregateId
      .then ->
        expect(doSomethingStub).to.have.been.calledOnce


    it 'should be possible to subscribe handlers to domain events', (done) ->
      exampleRemote.subscribeToDomainEvent 'SomethingCreated'
      .then (aggregateId) ->
        createSomethingStub()
        exampleRemote.unsubscribeFromDomainEvent aggregateId
      exampleRemote.command 'CreateSomething'
      .then ->
        expect(createSomethingStub).to.have.been.calledOnce
        done()


    it 'should be possible to subscribe handlers to domain events with specific aggregate ids', (done) ->
      exampleRemote.subscribeToDomainEventWithAggregateId 'SomethingModified'
      .then (aggregateId) ->
        modifySomethingStub()
        exampleRemote.unsubscribeFromDomainEvent aggregateId
      exampleRemote.command 'CreateSomething'
      .then (aggregateId) ->
        exampleRemote.command 'ModifySomething', id: aggregateId
        .then ->
          expect(modifySomethingStub).to.have.been.calledOnce
          done()

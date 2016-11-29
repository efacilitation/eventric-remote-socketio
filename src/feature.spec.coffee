describe 'socket io remote endpoint (socket io remote client integration)', ->
  eventric = null
  socketIoRemoteEndpoint = null
  socketIoRemoteClient = null
  socketIoServer = null
  socketIoClient = null


  before (done) ->
    eventric = require 'eventric'

    socketIoServer = require('socket.io')()
    socketIoServer.listen 3000

    SocketIoRemoteEndpoint = require './endpoint'
    socketIoRemoteEndpoint = new SocketIoRemoteEndpoint
    socketIoRemoteEndpoint.initialize socketIoServer: socketIoServer

    eventric.addRemoteEndpoint socketIoRemoteEndpoint

    socketIoClient = require('socket.io-client')('http://localhost:3000')
    socketIoClient.on 'connect', ->
      socketIoRemoteClient = require 'eventric-remote-socketio-client'
      socketIoRemoteClient.initialize ioClientInstance: socketIoClient
      .then done
      .catch done

    return


  after ->
    socketIoRemoteEndpoint.close()
    socketIoRemoteClient.disconnect()
    require._cache = {}


  describe 'creating an example context and adding a socketio remote endpoint', ->
    exampleRemote = null
    socketIoRemoteClient = null
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
          throw new Error 'The error message'
        DoSomething: doSomethingStub

      exampleContext.initialize()
      .then ->
        exampleRemote = eventric.remoteContext 'Example'
        exampleRemote.setClient socketIoRemoteClient


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


    it 'should be possible to subscribe handlers to domain events', ->
      exampleRemote.subscribeToDomainEvent 'SomethingCreated'
      .then (aggregateId) ->
        createSomethingStub()
        exampleRemote.unsubscribeFromDomainEvent aggregateId
      exampleRemote.command 'CreateSomething'
      .then ->
        expect(createSomethingStub).to.have.been.calledOnce


    it 'should be possible to subscribe handlers to domain events with specific aggregate ids', ->
      exampleRemote.subscribeToDomainEventWithAggregateId 'SomethingModified'
      .then (aggregateId) ->
        modifySomethingStub()
        exampleRemote.unsubscribeFromDomainEvent aggregateId

      exampleRemote.command 'CreateSomething'
      .then (aggregateId) ->
        exampleRemote.command 'ModifySomething', id: aggregateId
      .then ->
        expect(modifySomethingStub).to.have.been.calledOnce

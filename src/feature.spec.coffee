chai      = require 'chai'
expect    = chai.expect
sinon     = require 'sinon'
eventric  = require 'eventric'
sinonChai = require 'sinon-chai'
chai.use sinonChai

describe 'SocketIO Remote', ->
  socketIORemoteEndpoint = null
  socketIORemoteClient = null
  socketServer = null
  socketClient = null

  doSomethingStub = null

  before (done) ->
    socketServer = require('socket.io')()
    socketServer.listen 3000
    socketIORemoteEndpoint = require './endpoint'
    socketIORemoteEndpoint.initialize ioInstance: socketServer, ->
      eventric.addRemoteEndpoint 'socketio', socketIORemoteEndpoint
      socketClient = require('socket.io-client')('http://localhost:3000')
      socketClient.on 'connect', ->
        socketIORemoteClient = require 'eventric-remote-socketio-client'
        socketIORemoteClient.initialize ioClientInstance: socketClient, ->
          done()


  after ->
    socketIORemoteEndpoint.close()
    socketIORemoteClient.disconnect()
    require._cache = {}


  describe 'given we created an example context and added a socketio remote endpoint', ->
    exampleRemote = null
    socketIORemoteClient = null

    beforeEach (done) ->

      exampleContext = require './example_context'

      doSomethingStub = sinon.stub()
      exampleContext.addCommandHandlers
        DoSomething: (params, promise) ->
          doSomethingStub()
          promise.resolve()

      exampleContext.initialize()
      .then ->
        exampleRemote = eventric.remote 'Example'
        exampleRemote.addClient 'socketio', socketIORemoteClient
        exampleRemote.set 'default client', 'socketio'
        done()


    it 'then we should be able to receive and execute commands', (done) ->
      exampleRemote.command 'DoSomething'
      .then ->
        expect(doSomethingStub).to.have.been.calledOnce
        done()


    it 'then we should be able to subscribe handlers to domain events', (done) ->
      exampleRemote.subscribeToDomainEvent 'SomethingCreated'
      .then (subscriberId) ->
        exampleRemote.unsubscribeFromDomainEvent subscriberId
        done()
      exampleRemote.command 'CreateSomething'


    it 'then we should be able to subscribe handlers to domain events with specific aggregate ids', (done) ->
      exampleRemote.command 'CreateSomething'
      .then (id) ->

        exampleRemote.subscribeToDomainEventWithAggregateId 'SomethingModified', id, ->
          done()

        .then ->
          exampleRemote.command 'ModifySomething', id: id

chai      = require 'chai'
expect    = chai.expect
sinon     = require 'sinon'
eventric  = require 'eventric'
sinonChai = require 'sinon-chai'
chai.use sinonChai

describe 'SocketIO Remote', ->
  socketIORemoteEndpoint = null
  doSomethingStub = null

  after ->
    # socket.io close does not work with v1.0, thats why
    if @currentTest.state is 'passed'
      process.exit 0

    else
      process.exit 1


  describe 'given we created an example context and added a socketio remote endpoint', ->
    beforeEach (done) ->
      socketIORemoteEndpoint = require './endpoint'
      socketIORemoteEndpoint.initialize ->
        eventric.addRemoteEndpoint 'socketio', socketIORemoteEndpoint

        doSomethingStub = sinon.stub()
        exampleContext = eventric.context 'Example'
        exampleContext.addCommandHandlers
          DoSomething: (params, callback) ->
            doSomethingStub()
            callback()

        exampleContext.initialize ->
          done()


    describe 'when we then create a remote with a socketio client', ->
      exampleRemote = null
      beforeEach (done) ->
        sockeIORemoteClient = require 'eventric-remote-socketio-client'
        sockeIORemoteClient.initialize ->
          exampleRemote = eventric.remote 'Example'
          exampleRemote.addClient 'socketio', sockeIORemoteClient
          exampleRemote.set 'default client', 'socketio'

          done()


      it 'then we should be able to receive and execute commands', (done) ->
        exampleRemote.command 'DoSomething'
        .then ->
          expect(doSomethingStub).to.have.been.calledOnce
          done()

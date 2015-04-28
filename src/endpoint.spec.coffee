chai   = require 'chai'
expect = chai.expect
sinon  = require 'sinon'

describe.only 'endpoint', ->
  sandbox = null
  endpoint = null
  ioStub = null

  beforeEach ->
    sandbox = sinon.sandbox.create()
    endpoint = require './endpoint'

    ioStub =
      sockets:
        on: sandbox.stub()


  afterEach ->
    sandbox.restore()


  describe '#initialize', ->

    it 'should register the connection handler', ->
      endpoint.initialize
        ioInstance: ioStub

      expect(ioStub.sockets.on.calledWith 'connection', sinon.match.func).to.be.ok


  describe 'receiving a JoinRoom event', ->
    socketStub = null

    beforeEach ->
      socketStub =
        on: sandbox.stub()
        join: sandbox.stub()
        leave: sandbox.stub()
      ioStub.sockets.on.withArgs('connection').yields socketStub


    it 'should join the room', ->
      socketStub.on.withArgs('JoinRoom').yields 'RoomName'
      endpoint.initialize
        ioInstance: ioStub
      expect(socketStub.join.calledWith 'RoomName').to.be.ok


  describe 'receiving a LeaveRoom event', ->

    socketStub = null

    beforeEach ->
      socketStub =
        on: sandbox.stub()
        join: sandbox.stub()
        leave: sandbox.stub()
      ioStub.sockets.on.withArgs('connection').yields socketStub


    it 'should leave the room', ->
      socketStub.on.withArgs('LeaveRoom').yields 'RoomName'
      endpoint.initialize
        ioInstance: ioStub
      expect(socketStub.leave.calledWith 'RoomName').to.be.ok


  describe 'receiving a RPC_Request event', ->
    socketStub = null
    rpcRequestFake = null
    rpcHandlerStub = null

    beforeEach ->
      rpcRequestFake =
        rpcId: 123
      socketStub =
        on: sandbox.stub()
        emit: sandbox.stub()
      rpcHandlerStub = sandbox.stub()
      ioStub.sockets.on.withArgs('connection').yields socketStub


    describe 'always', ->

      beforeEach ->
        endpoint.initialize
          ioInstance: ioStub


      it 'should execute the configured rpc handler', ->
        endpoint.setRPCHandler rpcHandlerStub
        socketStub.on.firstCall.args[1] rpcRequestFake
        expect(rpcHandlerStub.calledWith rpcRequestFake, sinon.match.func).to.be.ok


      it 'should emit the return value of the configured handler as RPC_Response', ->
        responseFake = {}
        rpcHandlerStub.yields null, responseFake
        endpoint.setRPCHandler rpcHandlerStub
        socketStub.on.firstCall.args[1] rpcRequestFake
        expect(socketStub.emit.calledWith 'RPC_Response', rpcId: rpcRequestFake.rpcId, err: null, data: responseFake).to.be.ok


    describe 'given a rpc request middleware', ->

      rpcRequestMiddlewareStub = null

      beforeEach ->
        rpcRequestMiddlewareStub = sandbox.stub()
        endpoint.initialize
          ioInstance: ioStub
          rpcRequestMiddleware: rpcRequestMiddlewareStub


      it 'should pass in the rpc request data, the assiocated socket and a done callback', ->
        socketStub.on.firstCall.args[1] rpcRequestFake
        expect(rpcRequestMiddlewareStub).to.have.been.called
        expect(rpcRequestMiddlewareStub.firstCall.args[0]).to.equal rpcRequestFake
        expect(rpcRequestMiddlewareStub.firstCall.args[1]).to.equal socketStub


      it 'should execute the configured rpc handler when the middleware is finished', ->
        rpcRequestMiddlewareStub.yields()
        socketStub.on.firstCall.args[1] rpcRequestFake
        expect(rpcHandlerStub).to.have.been.called


  describe '#publish', ->

    channelStub = null

    beforeEach ->
      channelStub =
        emit: sandbox.stub()
      endpoint.initialize
        ioInstance: ioStub

      ioStub.to = sandbox.stub().returns channelStub

    describe 'given only a context name', ->
      it 'should emit an event with payload to the correct channel', ->
        payload = {}
        endpoint.publish 'context', payload

        expect(ioStub.to.calledWith 'context').to.be.ok
        expect(channelStub.emit.calledWith 'context', payload).to.be.ok


    describe 'given a context name and event name', ->
      it 'should emit an event with payload to the correct channel', ->
        payload = {}
        endpoint.publish 'context', 'EventName', payload

        expect(ioStub.to.calledWith 'context/EventName').to.be.ok
        expect(channelStub.emit.calledWith 'context/EventName', payload).to.be.ok


    describe 'given a context name, event name and aggregate id', ->
      it 'should emit an event with payload to the correct channel', ->
        payload = {}
        endpoint.publish 'context', 'EventName', '12345', payload

        expect(ioStub.to.calledWith 'context/EventName/12345').to.be.ok
        expect(channelStub.emit.calledWith 'context/EventName/12345', payload).to.be.ok
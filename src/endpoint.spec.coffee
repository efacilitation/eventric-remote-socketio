chai   = require 'chai'
expect = chai.expect
sinon  = require 'sinon'

describe 'endpoint', ->
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

  describe '#setRPCHandler', ->
    socketStub = null

    beforeEach ->
      socketStub =
        on: sandbox.stub()
        emit: sandbox.stub()
      ioStub.sockets.on.withArgs('connection').yields socketStub
      endpoint.initialize
        ioInstance: ioStub


    it 'should execute the configured handler upon an incoming RPC_Request', ->
      rpcHandlerStub = sandbox.spy()
      endpoint.setRPCHandler rpcHandlerStub

      rpcRequestStub =
        rpcId: 123
      # withArgs
      socketStub.on.firstCall.args[1] rpcRequestStub

      expect(rpcHandlerStub.calledWith rpcRequestStub, sinon.match.func).to.be.ok


    it 'should emit the return value of the configured handler as RPC_Response', ->
      rpcRequestStub =
        rpcId: 123
      responseStub = {}

      rpcHandlerStub = sandbox.stub().yields null, responseStub
      endpoint.setRPCHandler rpcHandlerStub

      socketStub.on.firstCall.args[1] rpcRequestStub

      expect(socketStub.emit.calledWith 'RPC_Response', rpcId: rpcRequestStub.rpcId, err: null, data: responseStub).to.be.ok


  describe '#publish', ->

    it 'should emit an event with payload to the correct channel', ->
      channelStub =
       emit: sandbox.stub()
      endpoint.initialize
        ioInstance: ioStub

      ioStub.to = sandbox.stub().returns channelStub
      payload = {}
      endpoint.publish 'MyEventName', payload

      expect(ioStub.to.calledWith 'MyEventName').to.be.ok
      expect(channelStub.emit.calledWith 'MyEventName', payload).to.be.ok
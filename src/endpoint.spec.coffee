chai   = require 'chai'
expect = chai.expect
sinon  = require 'sinon'
eventricTesting = require 'eventric-testing'

describe 'SocketIO Remote', ->
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
      rpcHandlerStub = sandbox.stub().returns eventricTesting.resolve()
      endpoint.setRPCHandler rpcHandlerStub

      rpcRequestStub =
        rpcId: 123

      socketStub.on.firstCall.args[1] rpcRequestStub

      expect(rpcHandlerStub.calledWith rpcRequestStub).to.be.ok


    it 'should emit the response value of the configured handler as RPC_Response', ->
      rpcRequestStub =
        rpcId: 123
      responseStub = foo: 'bar'

      rpcHandlerStub = sandbox.stub().returns eventricTesting.resolve responseStub
      endpoint.setRPCHandler rpcHandlerStub

      socketStub.on.firstCall.args[1] rpcRequestStub

      expect(socketStub.emit.calledWith 'RPC_Response', rpcId: rpcRequestStub.rpcId, data: responseStub).to.be.ok


    it 'should emit the error value of the configured handler as RPC_Response', ->
      rpcRequestStub =
        rpcId: 123
      responseStub = foo: 'bar'

      rpcHandlerStub = sandbox.stub().returns eventricTesting.reject responseStub
      endpoint.setRPCHandler rpcHandlerStub

      socketStub.on.firstCall.args[1] rpcRequestStub

      expect(socketStub.emit.calledWith 'RPC_Response', rpcId: rpcRequestStub.rpcId, err: responseStub).to.be.ok

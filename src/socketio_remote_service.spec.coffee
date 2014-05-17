chai   = require 'chai'
expect = chai.expect
sinon  = require 'sinon'

describe 'SocketIORemoteService', ->
  it 'should emit the result of the RemoteService handle function', ->
    socketIORemoteService = require './socketio_remote_service'
    sandbox = sinon.sandbox.create()

    rpcId = 42

    handleResult =
      got: 'handled'
    remoteServiceStub =
      handle: sandbox.stub().yields null, handleResult

    rpcRequest =
      rpcId: rpcId
      do: 'something'
    socketIOStub = sandbox.stub()
    socketIOStub.on = sandbox.stub().yields rpcRequest
    socketIOStub.emit = sandbox.stub()

    expectedRpcResponse =
      rpcId: rpcId
      err: null
      data: handleResult

    socketIORemoteService.initialize remoteServiceStub, socketIOStub
    expect(socketIOStub.emit.calledWith 'RPC_Response', expectedRpcResponse).to.be.true

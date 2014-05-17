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
    socketIOSocketStub = sandbox.stub()
    socketIOSocketStub.on = sandbox.stub().yields rpcRequest
    socketIOSocketStub.emit = sandbox.stub()
    socketIOStub =
      sockets:
        on: sandbox.stub().yields socketIOSocketStub

    expectedRpcResponse =
      rpcId: rpcId
      err: null
      data: handleResult

    socketIORemoteService.initialize remoteServiceStub, socketIOStub
    expect(socketIOSocketStub.emit.calledWith 'RPC_Response', expectedRpcResponse).to.be.true

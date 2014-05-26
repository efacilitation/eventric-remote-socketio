chai   = require 'chai'
expect = chai.expect
sinon  = require 'sinon'

describe 'SocketIORemoteService', ->

  sandbox = null
  socketIORemoteService = null
  remoteServiceMock = null
  socketIOMock = null
  socketIOSocketMock = null
  rpcId = 42

  beforeEach ->
    sandbox = sinon.sandbox.create()
    socketIORemoteService = require './socketio_remote_service'
    remoteServiceMock =
      handle: sandbox.stub()
    rpcRequest =
      rpcId: rpcId
      do: 'something'
    socketIOSocketMock =
      on: sandbox.stub().yields rpcRequest
      emit: sandbox.stub()
    socketIOMock =
      sockets:
        on: sandbox.stub().yields socketIOSocketMock


  it 'should emit the result of the RemoteService handle function', ->

    responseData =
      foo: 'bar'
    remoteServiceMock.handle.yields null, responseData
    socketIORemoteService.initialize remoteServiceMock, socketIOMock
    expectedRpcResponse =
      rpcId: rpcId
      err: null
      data: responseData
    expect(socketIOSocketMock.emit.calledWith 'RPC_Response', expectedRpcResponse).to.be.true


  it 'should remove all circular references before sending the response', ->
    responseData =
      number: 5
      string: 'string'
      object:
        foo: 'bar'

    responseData.circularReference = responseData
    responseData.object.nestedCircularReference = responseData.object
    remoteServiceMock.handle.yields null, responseData
    socketIORemoteService.initialize remoteServiceMock, socketIOMock

    receivedResponse = socketIOSocketMock.emit.getCall(0).args[1]
    receivedData = receivedResponse.data

    expect(receivedData.number).to.equal 5
    expect(receivedData.string).to.equal 'string'
    expect(receivedData.object.foo).to.equal 'bar'
    expect(receivedData.circularReference).to.equal '[Circular]'
    expect(receivedData.object.nestedCircularReference).to.equal '[Circular]'

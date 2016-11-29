# TODO: Refactor specs to test "addRpcRequestMiddleware" separately

describe 'socket io remote endpoint', ->
  sandbox = null
  socketIoRemoteEndpoint = null
  socketIoServerFake = null

  beforeEach ->
    sandbox = sinon.sandbox.create()
    SocketIoRemoteEndpoint = require './endpoint'
    socketIoRemoteEndpoint = new SocketIoRemoteEndpoint

    socketIoServerFake =
      sockets:
        on: sandbox.stub()


  afterEach ->
    sandbox.restore()


  initializeEndpoint = (socketIoRemoteEndpoint, options) ->
    socketIoRemoteEndpoint.initialize options
    return new Promise (resolve) -> setTimeout resolve


  describe '#initialize', ->

    it 'should throw an error given no socket io server instance', ->
      expect(-> socketIoRemoteEndpoint.initialize {}).to.throw Error, 'No socket io server instance passed'


    it 'should register a connection handler on the Socket.IO server', ->
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(socketIoServerFake.sockets.on).to.have.been.calledWith 'connection', sinon.match.func


  describe 'receiving an eventric:joinRoom socket event', ->
    socketFake = null

    beforeEach ->
      socketFake =
        on: sandbox.stub()
        join: sandbox.stub()
        leave: sandbox.stub()
      socketIoServerFake.sockets.on.withArgs('connection').yields socketFake
      socketFake.on.withArgs('eventric:joinRoom').yields 'RoomName'


    it 'should join the room', ->
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(socketFake.join).to.have.been.calledWith 'RoomName'


    it 'should call the middleware and pass in the room name and the assiocated socket given a rpc request middleware', ->
      rpcRequestMiddlewareFake = sandbox.stub().returns Promise.resolve()
      socketIoRemoteEndpoint.addRpcRequestMiddleware rpcRequestMiddlewareFake

      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(rpcRequestMiddlewareFake).to.have.been.called
        expect(rpcRequestMiddlewareFake.firstCall.args[0]).to.equal 'RoomName'
        expect(rpcRequestMiddlewareFake.firstCall.args[1]).to.equal socketFake


    describe 'given an rpc request middleware which resolves', ->

      it 'should join the room', ->
        rpcRequestMiddlewareFake = sandbox.stub().returns Promise.resolve()
        socketIoRemoteEndpoint.addRpcRequestMiddleware rpcRequestMiddlewareFake

        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
        .then ->
          expect(socketFake.join).to.have.been.calledWith 'RoomName'


    describe 'given an rpc request middleware which rejects', ->
      loggerFake = null
      errorFake = null
      rpcRequestMiddlewareFake = null


      beforeEach ->
        loggerFake =
          error: sandbox.stub()
        errorFake = new Error 'error-message'
        rpcRequestMiddlewareFake = sandbox.stub().returns Promise.reject errorFake
        socketIoRemoteEndpoint.addRpcRequestMiddleware rpcRequestMiddlewareFake


      it 'should not join the room', ->
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
          logger: loggerFake
        .then ->
          expect(socketFake.join.calledOnce).to.be.false


      it 'should log the error given a logger', ->
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
          logger: loggerFake
        .then ->
          expect(loggerFake.error).to.have.been.calledWith errorFake


      it 'should rethrow the error given no logger', (done) ->
        handleUnhandledRjection = null

        handleUnhandledRjection = (error) ->
          process.removeListener 'unhandledRejection', handleUnhandledRjection
          expect(error).to.be.equal error
          done()

        process.on 'unhandledRejection', handleUnhandledRjection

        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake

        return


  describe 'receiving an eventric:leaveRoom socket event', ->

    it 'should leave the room', ->
      socketFake =
        on: sandbox.stub()
        join: sandbox.stub()
        leave: sandbox.stub()
      socketIoServerFake.sockets.on.withArgs('connection').yields socketFake
      socketFake.on.withArgs('eventric:leaveRoom').yields 'RoomName'
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(socketFake.leave.calledWith 'RoomName').to.be.ok


  describe 'receiving an eventric:rpcRequest event', ->
    socketFake = null
    rpcRequestFake = null
    rpcHandlerStub = null

    beforeEach ->
      rpcRequestFake =
        rpcId: 123
      socketFake =
        on: sandbox.stub()
        emit: sandbox.stub()
      rpcHandlerStub = sandbox.stub()
      socketIoServerFake.sockets.on.withArgs('connection').yields socketFake
      socketFake.on.withArgs('eventric:rpcRequest').yields rpcRequestFake
      socketIoRemoteEndpoint.setRPCHandler rpcHandlerStub


    it 'should execute the configured rpc handler', ->
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(rpcHandlerStub).to.have.been.calledWith rpcRequestFake, sinon.match.func


    it 'should emit the return value of the configured handler as eventric:rpcResponse', ->
      responseFake = {}
      rpcHandlerStub.yields null, responseFake
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(socketFake.emit).to.have.been.calledWith 'eventric:rpcResponse',
          rpcId: rpcRequestFake.rpcId
          error: null
          data: responseFake


    it 'should call the middleware with the rpc request data and the assiocated socket given a rpc request middleware', ->
      rpcRequestMiddlewareFake = sandbox.stub().returns Promise.resolve()
      socketIoRemoteEndpoint.addRpcRequestMiddleware rpcRequestMiddlewareFake

      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(rpcRequestMiddlewareFake).to.have.been.called
        expect(rpcRequestMiddlewareFake.firstCall.args[0]).to.equal rpcRequestFake
        expect(rpcRequestMiddlewareFake.firstCall.args[1]).to.equal socketFake


    describe 'given the configured rpc handler rejects', ->

      it 'should emit the an eventric:rpcResponse event with an error', ->
        error = new Error 'The error message'
        rpcHandlerStub.yields error, null
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
        .then ->
          expect(socketFake.emit).to.have.been.calledWith 'eventric:rpcResponse',
            rpcId: rpcRequestFake.rpcId
            error: sinon.match.has 'message', 'The error message'
            data: null


      it 'should emit the an eventric:rpcResponse event with a serializable error object', ->
        error = new Error 'The error message'
        rpcHandlerStub.yields error, null
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
        .then ->
          receivedError = socketFake.emit.getCall(0).args[1].error
          expect(receivedError).to.be.an.instanceOf Object
          expect(receivedError).not.to.be.an.instanceOf Error


      it 'should emit the event with an error object including custom properties excluding the stack', ->
        error = new Error 'The error message'
        error.someProperty = 'someValue'
        rpcHandlerStub.yields error, null
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
        .then ->
          expect(socketFake.emit).to.have.been.calledWith 'eventric:rpcResponse',
            rpcId: rpcRequestFake.rpcId
            error:
              message: 'The error message'
              name: 'Error'
              someProperty: 'someValue'
            data: null


    describe 'given a rpc request middleware which resolves', ->
      rpcRequestMiddlewareFake = null
      responseFake = null

      beforeEach ->
        responseFake = {}
        rpcHandlerStub.yields null, responseFake

        rpcRequestMiddlewareFake = sandbox.stub().returns Promise.resolve()
        socketIoRemoteEndpoint.addRpcRequestMiddleware rpcRequestMiddlewareFake

        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake


      it 'should execute the configured rpc handler', ->
        expect(rpcHandlerStub).to.have.been.calledWith rpcRequestFake, sinon.match.func


      it 'should emit the return value of the configured handler as eventric:rpcResponse', ->
        expect(socketFake.emit).to.have.been.calledWith 'eventric:rpcResponse',
          rpcId: rpcRequestFake.rpcId
          error: null
          data: responseFake


    describe 'given an rpc request middleware which rejects', ->
      rpcRequestMiddlewareFake = null

      beforeEach ->
        errorFake = new Error 'error-message'
        rpcRequestMiddlewareFake = sandbox.stub().returns Promise.reject errorFake
        socketIoRemoteEndpoint.addRpcRequestMiddleware rpcRequestMiddlewareFake

        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake


      it 'should not execute the configured rpc handler', ->
        expect(rpcHandlerStub).to.not.have.been.calledWith rpcRequestFake, sinon.match.func


      it 'should emit an eventric:rpcResponse event with an error object', ->
        expect(socketFake.emit).to.have.been.calledWith 'eventric:rpcResponse',
          rpcId: rpcRequestFake.rpcId
          error: sinon.match.object
          data: null


  describe '#publish', ->
    channelFake = null

    beforeEach ->
      channelFake =
        emit: sandbox.stub()

      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        socketIoServerFake.to = sandbox.stub().returns channelFake


    it 'should emit an event with payload to the correct channel given only a context name', ->
      payload = {}
      socketIoRemoteEndpoint.publish 'context', payload

      expect(socketIoServerFake.to).to.have.been.calledWith 'context'
      expect(channelFake.emit).to.have.been.calledWith 'context', payload


    it 'should emit an event with payload to the correct channel given a context name and event name', ->
      payload = {}
      socketIoRemoteEndpoint.publish 'context', 'EventName', payload

      expect(socketIoServerFake.to).to.have.been.calledWith 'context/EventName'
      expect(channelFake.emit).to.have.been.calledWith 'context/EventName', payload


    it 'should emit an event with payload to the correct channel given a context name, event name and aggregate id', ->
      payload = {}
      socketIoRemoteEndpoint.publish 'context', 'EventName', '12345', payload

      expect(socketIoServerFake.to).to.have.been.calledWith 'context/EventName/12345'
      expect(channelFake.emit).to.have.been.calledWith 'context/EventName/12345', payload

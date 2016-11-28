describe 'socket io remote endpoint', ->
  sandbox = null
  socketIoRemoteEndpoint = null
  socketIoServerFake = null

  beforeEach ->
    sandbox = sinon.sandbox.create()
    socketIoRemoteEndpoint = require './endpoint'

    socketIoServerFake =
      sockets:
        on: sandbox.stub()


  afterEach ->
    sandbox.restore()


  initializeEndpoint = (endpoint, options) ->
    endpoint.initialize options
    return new Promise (resolve) -> setTimeout resolve


  describe '#initialize', ->

    it 'should register a connection handler on the Socket.IO server', ->
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(socketIoServerFake.sockets.on).to.have.been.calledWith 'connection', sinon.match.func


  describe 'receiving an eventric:joinRoom socket event', ->
    socketStub = null

    beforeEach ->
      socketStub =
        on: sandbox.stub()
        join: sandbox.stub()
        leave: sandbox.stub()
      socketIoServerFake.sockets.on.withArgs('connection').yields socketStub
      socketStub.on.withArgs('eventric:joinRoom').yields 'RoomName'


    it 'should join the room', ->
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(socketStub.join).to.have.been.calledWith 'RoomName'


    describe 'given an rpc request middleware', ->

      rpcRequestMiddlewareFake = null

      beforeEach ->
        rpcRequestMiddlewareFake = sandbox.stub()


      it 'should call the middleware and pass in the room name and the assiocated socket', ->
        rpcRequestMiddlewareFake.returns Promise.resolve()
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
          rpcRequestMiddleware: rpcRequestMiddlewareFake
        .then ->
          expect(rpcRequestMiddlewareFake).to.have.been.called
          expect(rpcRequestMiddlewareFake.firstCall.args[0]).to.equal 'RoomName'
          expect(rpcRequestMiddlewareFake.firstCall.args[1]).to.equal socketStub


      it 'should join the room given the middleware resolves', ->
        rpcRequestMiddlewareFake.returns Promise.resolve()
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
          rpcRequestMiddleware: rpcRequestMiddlewareFake
        .then ->
          expect(socketStub.join).to.have.been.calledWith 'RoomName'


      it 'should not join the room given the middleware rejects', ->
        rpcRequestMiddlewareFake.returns Promise.reject()
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
          rpcRequestMiddleware: rpcRequestMiddlewareFake
        .then ->
          expect(socketStub.join.calledOnce).to.be.false


  describe 'receiving an eventric:leaveRoom socket event', ->

    it 'should leave the room', ->
      socketStub =
        on: sandbox.stub()
        join: sandbox.stub()
        leave: sandbox.stub()
      socketIoServerFake.sockets.on.withArgs('connection').yields socketStub
      socketStub.on.withArgs('eventric:leaveRoom').yields 'RoomName'
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        expect(socketStub.leave.calledWith 'RoomName').to.be.ok


  describe 'receiving an eventric:rpcRequest event', ->
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
      socketIoServerFake.sockets.on.withArgs('connection').yields socketStub
      socketStub.on.withArgs('eventric:rpcRequest').yields rpcRequestFake
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
        expect(socketStub.emit).to.have.been.calledWith 'eventric:rpcResponse',
          rpcId: rpcRequestFake.rpcId
          error: null
          data: responseFake


    it 'should call the middleware with the rpc request data and the assiocated socket given a rpc request middleware', ->
      rpcRequestMiddlewareFake = sandbox.stub()
      rpcRequestMiddlewareFake.returns Promise.resolve()
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
        rpcRequestMiddleware: rpcRequestMiddlewareFake
      .then ->
        expect(rpcRequestMiddlewareFake).to.have.been.called
        expect(rpcRequestMiddlewareFake.firstCall.args[0]).to.equal rpcRequestFake
        expect(rpcRequestMiddlewareFake.firstCall.args[1]).to.equal socketStub


    describe 'given the configured rpc handler rejects', ->

      it 'should emit the an eventric:rpcResponse event with an error', ->
        error = new Error 'The error message'
        rpcHandlerStub.yields error, null
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
        .then ->
          expect(socketStub.emit).to.have.been.calledWith 'eventric:rpcResponse',
            rpcId: rpcRequestFake.rpcId
            error: sinon.match.has 'message', 'The error message'
            data: null


      it 'should emit the an eventric:rpcResponse event with a serializable error object', ->
        error = new Error 'The error message'
        rpcHandlerStub.yields error, null
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
        .then ->
          receivedError = socketStub.emit.getCall(0).args[1].error
          expect(receivedError).to.be.an.instanceOf Object
          expect(receivedError).not.to.be.an.instanceOf Error


      it 'should emit the event with an error object including custom properties excluding the stack', ->
        error = new Error 'The error message'
        error.someProperty = 'someValue'
        rpcHandlerStub.yields error, null
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
        .then ->
          expect(socketStub.emit).to.have.been.calledWith 'eventric:rpcResponse',
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
        rpcRequestMiddlewareFake = sandbox.stub()
        responseFake = {}
        rpcRequestMiddlewareFake.returns Promise.resolve()
        rpcHandlerStub.yields null, responseFake
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
          rpcRequestMiddleware: rpcRequestMiddlewareFake


      it 'should execute the configured rpc handler', ->
        expect(rpcHandlerStub).to.have.been.calledWith rpcRequestFake, sinon.match.func


      it 'should emit the return value of the configured handler as eventric:rpcResponse', ->
        expect(socketStub.emit).to.have.been.calledWith 'eventric:rpcResponse',
          rpcId: rpcRequestFake.rpcId
          error: null
          data: responseFake


    describe 'given an rpc request middleware which rejects', ->

      rpcRequestMiddlewareFake = null

      beforeEach ->
        error = new Error 'The error message'
        initializeEndpoint socketIoRemoteEndpoint,
          socketIoServer: socketIoServerFake
          rpcRequestMiddleware: sandbox.stub().returns Promise.reject ->
        new Promise (resolve) ->
          setTimeout resolve


      it 'should not execute the configured rpc handler', ->
        expect(rpcHandlerStub).to.not.have.been.calledWith rpcRequestFake, sinon.match.func


      it 'should emit an eventric:rpcResponse event with an error object', ->
        expect(socketStub.emit).to.have.been.calledWith 'eventric:rpcResponse',
          rpcId: rpcRequestFake.rpcId
          error: sinon.match.object
          data: null


  describe '#publish', ->

    channelStub = null

    beforeEach ->
      channelStub =
        emit: sandbox.stub()
      initializeEndpoint socketIoRemoteEndpoint,
        socketIoServer: socketIoServerFake
      .then ->
        socketIoServerFake.to = sandbox.stub().returns channelStub


    it 'should emit an event with payload to the correct channel given only a context name', ->
      payload = {}
      socketIoRemoteEndpoint.publish 'context', payload

      expect(socketIoServerFake.to).to.have.been.calledWith 'context'
      expect(channelStub.emit).to.have.been.calledWith 'context', payload


    it 'should emit an event with payload to the correct channel given a context name and event name', ->
      payload = {}
      socketIoRemoteEndpoint.publish 'context', 'EventName', payload

      expect(socketIoServerFake.to).to.have.been.calledWith 'context/EventName'
      expect(channelStub.emit).to.have.been.calledWith 'context/EventName', payload


    it 'should emit an event with payload to the correct channel given a context name, event name and aggregate id', ->
      payload = {}
      socketIoRemoteEndpoint.publish 'context', 'EventName', '12345', payload

      expect(socketIoServerFake.to).to.have.been.calledWith 'context/EventName/12345'
      expect(channelStub.emit).to.have.been.calledWith 'context/EventName/12345', payload

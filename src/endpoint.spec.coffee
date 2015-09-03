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

    it 'should register a connection handler on the Socket.IO server', ->
      endpoint.initialize
        ioInstance: ioStub

      expect(ioStub.sockets.on).to.have.been.calledWith 'connection', sinon.match.func


  describe 'receiving an eventric:joinRoom socket event', ->
    socketStub = null

    beforeEach ->
      socketStub =
        on: sandbox.stub()
        join: sandbox.stub()
        leave: sandbox.stub()
      ioStub.sockets.on.withArgs('connection').yields socketStub
      socketStub.on.withArgs('eventric:joinRoom').yields 'RoomName'


    it 'should join the room', ->
      endpoint.initialize
        ioInstance: ioStub
      expect(socketStub.join).to.have.been.calledWith 'RoomName'


    describe 'given a rpc request middleware', ->

      rpcRequestMiddlewareStub = null

      beforeEach ->
        rpcRequestMiddlewareStub = sandbox.stub()


      it 'should call the middleware and pass in the room name and the assiocated socket', (done) ->
        rpcRequestMiddlewareStub.returns new Promise (resolve) -> resolve()
        endpoint.initialize
          ioInstance: ioStub
          rpcRequestMiddleware: rpcRequestMiddlewareStub

        setTimeout ->
          expect(rpcRequestMiddlewareStub).to.have.been.called
          expect(rpcRequestMiddlewareStub.firstCall.args[0]).to.equal 'RoomName'
          expect(rpcRequestMiddlewareStub.firstCall.args[1]).to.equal socketStub
          done()


      it 'should join the room given the middleware resolves', (done) ->
        rpcRequestMiddlewareStub.returns Promise.resolve()
        endpoint.initialize
          ioInstance: ioStub
          rpcRequestMiddleware: rpcRequestMiddlewareStub
        setTimeout ->
          expect(socketStub.join).to.have.been.calledWith 'RoomName'
          done()


      it 'should not join the room given the middleware rejects', (done) ->
        rpcRequestMiddlewareStub.returns Promise.reject()
        endpoint.initialize
          ioInstance: ioStub
          rpcRequestMiddleware: rpcRequestMiddlewareStub
        setTimeout ->
          expect(socketStub.join.calledOnce).to.be.false
          done()


  describe 'receiving an eventric:leaveRoom socket event', ->

    it 'should leave the room', ->
      socketStub =
        on: sandbox.stub()
        join: sandbox.stub()
        leave: sandbox.stub()
      ioStub.sockets.on.withArgs('connection').yields socketStub
      socketStub.on.withArgs('eventric:leaveRoom').yields 'RoomName'
      endpoint.initialize
        ioInstance: ioStub
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
      ioStub.sockets.on.withArgs('connection').yields socketStub
      socketStub.on.withArgs('eventric:rpcRequest').yields rpcRequestFake
      endpoint.setRPCHandler rpcHandlerStub


    it 'should execute the configured rpc handler', ->
      endpoint.initialize
        ioInstance: ioStub
      expect(rpcHandlerStub).to.have.been.calledWith rpcRequestFake, sinon.match.func


    it 'should emit the return value of the configured handler as eventric:rpcResponse', ->
      responseFake = {}
      rpcHandlerStub.yields null, responseFake
      endpoint.initialize
        ioInstance: ioStub
      expect(socketStub.emit).to.have.been.calledWith 'eventric:rpcResponse',
        rpcId: rpcRequestFake.rpcId
        error: null
        data: responseFake


    it 'should call the middleware with the rpc request data and the assiocated socket given a rpc request middleware', (done) ->
      rpcRequestMiddlewareStub = sandbox.stub()
      rpcRequestMiddlewareStub.returns new Promise (resolve) -> resolve()
      endpoint.initialize
        ioInstance: ioStub
        rpcRequestMiddleware: rpcRequestMiddlewareStub

      setTimeout ->
        expect(rpcRequestMiddlewareStub).to.have.been.called
        expect(rpcRequestMiddlewareStub.firstCall.args[0]).to.equal rpcRequestFake
        expect(rpcRequestMiddlewareStub.firstCall.args[1]).to.equal socketStub
        done()


    describe 'given the configured rpc handler rejects', ->

      it 'should emit the an eventric:rpcResponse event with an error', ->
        error = new Error 'The error message'
        rpcHandlerStub.yields error, null
        endpoint.initialize
          ioInstance: ioStub
        expect(socketStub.emit).to.have.been.calledWith 'eventric:rpcResponse',
          rpcId: rpcRequestFake.rpcId
          error: sinon.match.has 'message', 'The error message'
          data: null


      it 'should emit the an eventric:rpcResponse event with a serializable error object', ->
        error = new Error 'The error message'
        rpcHandlerStub.yields error, null
        endpoint.initialize
          ioInstance: ioStub
        receivedError = socketStub.emit.getCall(0).args[1].error
        expect(receivedError).to.be.an.instanceOf Object
        expect(receivedError).not.to.be.an.instanceOf Error


      it 'should emit the event with an error object including custom properties excluding the stack', ->
        error = new Error 'The error message'
        error.someProperty = 'someValue'
        rpcHandlerStub.yields error, null
        endpoint.initialize
          ioInstance: ioStub
        expect(socketStub.emit).to.have.been.calledWith 'eventric:rpcResponse',
          rpcId: rpcRequestFake.rpcId
          error:
            message: 'The error message'
            name: 'Error'
            someProperty: 'someValue'
          data: null


    describe 'given a rpc request middleware which resolves', ->

      rpcRequestMiddlewareStub = null
      responseFake = null


      beforeEach (done) ->
        rpcRequestMiddlewareStub = sandbox.stub()
        responseFake = {}
        rpcRequestMiddlewareStub.returns new Promise (resolve) -> resolve()
        rpcHandlerStub.yields null, responseFake
        endpoint.initialize
          ioInstance: ioStub
          rpcRequestMiddleware: rpcRequestMiddlewareStub
        setTimeout ->
          done()


      it 'should execute the configured rpc handler', ->
        expect(rpcHandlerStub.calledWith rpcRequestFake, sinon.match.func).to.be.ok


      it 'should emit the return value of the configured handler as eventric:rpcResponse', ->
        expect(socketStub.emit.calledWith 'eventric:rpcResponse', rpcId: rpcRequestFake.rpcId, error: null, data: responseFake).to.be.ok


    describe 'given a rpc request middleware which rejects', ->

      rpcRequestMiddlewareStub = null

      beforeEach (done) ->
        rpcRequestMiddlewareStub = sandbox.stub()
        error = new Error 'The error message'
        rpcRequestMiddlewareStub.returns Promise.reject error
        rpcHandlerStub.yields null, {}
        endpoint.initialize
          ioInstance: ioStub
          rpcRequestMiddleware: rpcRequestMiddlewareStub
        setTimeout ->
          done()


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
      endpoint.initialize
        ioInstance: ioStub

      ioStub.to = sandbox.stub().returns channelStub

    it 'should emit an event with payload to the correct channel given only a context name', ->
      payload = {}
      endpoint.publish 'context', payload

      expect(ioStub.to).to.have.been.calledWith 'context'
      expect(channelStub.emit).to.have.been.calledWith 'context', payload


    it 'should emit an event with payload to the correct channel given a context name and event name', ->
      payload = {}
      endpoint.publish 'context', 'EventName', payload

      expect(ioStub.to).to.have.been.calledWith 'context/EventName'
      expect(channelStub.emit).to.have.been.calledWith 'context/EventName', payload


    it 'should emit an event with payload to the correct channel given a context name, event name and aggregate id', ->
      payload = {}
      endpoint.publish 'context', 'EventName', '12345', payload

      expect(ioStub.to).to.have.been.calledWith 'context/EventName/12345'
      expect(channelStub.emit).to.have.been.calledWith 'context/EventName/12345', payload
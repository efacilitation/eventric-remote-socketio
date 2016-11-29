class SocketIORemoteEndpoint

  constructor: ->
    @_rpcRequestMiddlewareArray = []


  initialize: ({socketIoServer, logger}) ->
    if not socketIoServer
      throw new Error 'No socket io server instance passed'
    @_socketIoServer = socketIoServer
    @_logger = logger

    @_addSocketIoEventBindings()


  addRpcRequestMiddleware: (rpcRequestMiddleware) ->
    @_rpcRequestMiddlewareArray.push rpcRequestMiddleware


  _addSocketIoEventBindings: ->
    @_socketIoServer.sockets.on 'connection', (socket) =>

      socket.on 'eventric:rpcRequest', (rpcRequest) =>
        @_handleRpcRequestEvent rpcRequest, socket


      socket.on 'eventric:joinRoom', (roomName) =>
        @_handleJoinRoomEvent roomName, socket


      socket.on 'eventric:leaveRoom', (roomName) ->
        socket.leave roomName



  setRPCHandler: (handleRPCRequest) ->
    @_handleRPCRequest = handleRPCRequest


  _handleRpcRequestEvent: (rpcRequest, socket) ->
    emitRpcResponse = (error, response) =>
      if error
        error = @_convertErrorToSerializableObject error

      rpcId = rpcRequest.rpcId
      socket.emit 'eventric:rpcResponse',
        rpcId: rpcId
        error: error
        data: response

    @_executeRpcRequestMiddleware rpcRequest, socket
    .then =>
      @_handleRPCRequest rpcRequest, emitRpcResponse
    .catch (error) ->
      emitRpcResponse error, null


  _handleJoinRoomEvent: (roomName, socket) ->
    @_executeRpcRequestMiddleware roomName, socket
    .then ->
      socket.join roomName
    .catch (error) =>
      if @_logger
        @_logger.error error, '\n', error.stack
      else
        throw error


  _executeRpcRequestMiddleware: (data, socket) ->
    rpcRequestMiddlewarePromise = Promise.resolve()
    @_rpcRequestMiddlewareArray.forEach (rpcRequestMiddleware) ->
      rpcRequestMiddlewarePromise = rpcRequestMiddlewarePromise.then ->
        return rpcRequestMiddleware data, socket
    rpcRequestMiddlewarePromise


  _convertErrorToSerializableObject: (error) ->
    serializableErrorObject =
      name: error.name
      message: error.message

    Object.keys(error).forEach (key) ->
      serializableErrorObject[key] = error[key]

    return serializableErrorObject


  publish: (context, [domainEventName, aggregateId]..., payload) ->
    fullEventName = @_getFullEventName context, domainEventName, aggregateId
    @_socketIoServer.to(fullEventName).emit fullEventName, payload


  _getFullEventName: (context, domainEventName, aggregateId) ->
    fullEventName = context

    if domainEventName
      fullEventName += "/#{domainEventName}"

    if aggregateId
      fullEventName += "/#{aggregateId}"

    return fullEventName


  close: ->
    @_socketIoServer.close()


module.exports = SocketIORemoteEndpoint

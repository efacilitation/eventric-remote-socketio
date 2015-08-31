class SocketIORemoteEndpoint

  initialize: (options = {}, callback = ->) ->
    @_processOptions options

    @_io.sockets.on 'connection', (socket) =>
      socket.on 'eventric:rpcRequest', (rpcRequest) =>
        @_handleRpcRequestEvent rpcRequest, socket

      # TODO: Remove JoinRoom event listener as soon as stream subscriptions are implenented correctly
      socket.on 'eventric:joinRoom', (roomName) =>
        @_rpcRequestMiddleware roomName, socket
        .then ->
          socket.join roomName
        .catch (error) ->
          # TODO: Error handling?

      # TODO: Remove LeaveRoom event listener as soon as stream subscriptions are implenented correctly
      socket.on 'eventric:leaveRoom', (roomName) ->
        socket.leave roomName

    callback()


  setRPCHandler: (@_handleRPCRequest) ->


  _processOptions: (options) ->
    if options.ioInstance
      @_io = options.ioInstance
    else
      # TODO: Consider testing
      @_io = require('socket.io')()
      @_io.listen 3000

    if options.rpcRequestMiddleware
      @_rpcRequestMiddleware = options.rpcRequestMiddleware
    else
      @_rpcRequestMiddleware = ->
        then: (callback) ->
          callback()
          catch: ->


  _handleRpcRequestEvent: (rpcRequest, socket) ->
    emitRpcResponse = (error, response) ->
      if error? and error.message and error.name
        error = message: error.message, name: error.name

      rpcId = rpcRequest.rpcId
      socket.emit 'eventric:rpcResponse',
        rpcId: rpcId
        error: error
        data: response

    @_rpcRequestMiddleware rpcRequest, socket
    .then =>
      @_handleRPCRequest rpcRequest, emitRpcResponse
    .catch (error) ->
      emitRpcResponse error, null


  publish: (context, [domainEventName, aggregateId]..., payload) ->
    fullEventName = @_getFullEventName context, domainEventName, aggregateId
    @_io.to(fullEventName).emit fullEventName, payload


  _getFullEventName: (context, domainEventName, aggregateId) ->
    fullEventName = context
    if domainEventName
      fullEventName += "/#{domainEventName}"
    if aggregateId
      fullEventName += "/#{aggregateId}"
    fullEventName


  close: ->
    @_io.close()


module.exports = new SocketIORemoteEndpoint

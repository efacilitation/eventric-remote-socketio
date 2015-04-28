class SocketIORemoteEndpoint

  initialize: (options = {}, callback = ->) ->
    if options.ioInstance
      @_io = options.ioInstance
    else
      # TODO: Consider testing
      @_io = require('socket.io')()
      @_io.listen 3000

    if options.rpcRequestMiddleware
      @_rpcRequestMiddleware = options.rpcRequestMiddleware
    else
      @_rpcRequestMiddleware = (request, socket, callback) ->
        callback()

    @_io.sockets.on 'connection', (socket) =>
      socket.on 'RPC_Request', (rpcRequest) =>

        emitRpcResponse = (error, response) =>
          rpcId = rpcRequest.rpcId
          socket.emit 'RPC_Response',
            rpcId: rpcId
            err: error
            data: response

        @_rpcRequestMiddleware rpcRequest, socket, =>
          @_handleRPCRequest rpcRequest, emitRpcResponse


      socket.on 'JoinRoom', (roomName) ->
        socket.join roomName


      socket.on 'LeaveRoom', (roomName) ->
        socket.leave roomName


    callback()


  close: ->
    @_io.close()


  setRPCHandler: (@_handleRPCRequest) ->


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


module.exports = new SocketIORemoteEndpoint
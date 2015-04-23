class SocketIORemoteEndpoint

  initialize: (options = {}, callback = ->) ->
    if options.ioInstance
      @_io = options.ioInstance
    else
      @_io = require('socket.io')()
      @_io.listen 3000

    @_io.sockets.on 'connection', (socket) =>
      socket.on 'RPC_Request', (RPC_Request) =>
        rpcId = RPC_Request.rpcId
        @_handleRPCRequest RPC_Request
        .then (response) ->
          socket.emit 'RPC_Response',
            rpcId: rpcId
            data: response

        .catch (err) ->
          # TODO: consider renaming to RPC_Error
          socket.emit 'RPC_Response',
            rpcId: rpcId
            err: err


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
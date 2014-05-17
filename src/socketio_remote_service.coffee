class SocketIORemoteService

  initialize: (@_remoteService, @_io) ->
    @_io.sockets.on 'connection', (socket) =>
      socket.on 'RPC_Request', (RPC_Request) =>
        @_remoteService.handle RPC_Request, (err, response) =>
          rpcId = RPC_Request.rpcId
          socket.emit 'RPC_Response', {rpcId: rpcId, err: err, data: response}


module.exports = new SocketIORemoteService
class SocketIORemoteService

  initialize: (@_remoteService, @_io) ->
    @_io.on 'RPC_Request', (RPC_Request) =>
      @_remoteService.handle RPC_Request, (err, response) =>
        rpcId = RPC_Request.rpcId
        @_io.emit 'RPC_Response', {rpcId: rpcId, err: err, data: response}


module.exports = new SocketIORemoteService
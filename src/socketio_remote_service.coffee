class SocketIORemoteService

  initialize: (@_remoteService, @_io) ->
    @_io.sockets.on 'connection', (socket) =>
      socket.on 'RPC_Request', (RPC_Request) =>
        @_remoteService.handle RPC_Request, (err, response) =>
          rpcId = RPC_Request.rpcId
          @_removeCircularReferences response
          socket.emit 'RPC_Response', {rpcId: rpcId, err: err, data: response}


  _removeCircularReferences: (data, parentReferences = []) ->
    parentReferencesAndSelf = parentReferences.concat [data]
    for key, value of data
      if typeof value is 'object'
        if parentReferencesAndSelf.indexOf(value) > -1
          data[key] = '[Circular]'
        else
          @_removeCircularReferences value, parentReferencesAndSelf



module.exports = new SocketIORemoteService
class SocketIORemoteEndpoint

  initialize: ([options]..., callback=->) ->
    options ?= {}
    @_sockets = []

    if options.ioInstance
      @_io = options.ioInstance
    else
      @_io = require('socket.io')()
      listen = true

    @_io.sockets.on 'connection', (socket) =>
      @_sockets.push socket
      socket.on 'RPC_Request', (RPC_Request) =>
        @_handleRPCRequest RPC_Request, (err, response) =>
          rpcId = RPC_Request.rpcId
          socket.emit 'RPC_Response', {rpcId: rpcId, err: err, data: response}

    if listen
      @_io.listen 3000
      callback()


  close: ->
    @_io.engine.close()


  setRPCHandler: (@_handleRPCRequest) ->



module.exports = new SocketIORemoteEndpoint
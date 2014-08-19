class SocketIORemoteEndpoint

  initialize: (options = {}, callback = ->) ->

    if options.ioInstance
      @_io = options.ioInstance
    else
      @_io = require('socket.io')()
      @_io.listen 3000

    @_io.sockets.on 'connection', (socket) =>
      socket.on 'RPC_Request', (RPC_Request) =>
        @_handleRPCRequest RPC_Request, (err, response) =>
          rpcId = RPC_Request.rpcId
          socket.emit 'RPC_Response',
            rpcId: rpcId
            err: err
            data: response

    callback()


  close: ->
    @_io.engine.close()


  setRPCHandler: (@_handleRPCRequest) ->


  publish: (eventName, payload) ->
    @_io.to(eventName).emit eventName, payload


module.exports = new SocketIORemoteEndpoint
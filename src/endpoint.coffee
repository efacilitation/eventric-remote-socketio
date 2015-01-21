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

      socket.on 'RPS_Request', (RPS_Request) =>
        rpsId = RPS_Request.rpsId
        # its a subscriber request, we need to push a proxy
        # subscriber function to the params
        subscriberProxyFn = ->
          # RPS_Publish
          socket.emit 'RPS_Publish',
            subscriberId: RPS_Request.subscriberId
            payload: Array.prototype.slice.call arguments

        RPS_Request.params.push subscriberProxyFn

        @_handleRPCRequest RPS_Request
        .then (response) ->
          socket.emit 'RPS_Response',
            rpsId: rpsId
            data: response

        .catch (err) ->
          # TODO: consider renaming to RPS_Error
          socket.emit 'RPS_Response',
            rpsId: rpsId
            err: err


    callback()


  close: ->
    @_io.close()


  setRPCHandler: (@_handleRPCRequest) ->



module.exports = new SocketIORemoteEndpoint
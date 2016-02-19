## eventric Socket.IO remote endpoint [![Build Status](https://travis-ci.org/efacilitation/eventric-remote-socketio-endpoint.svg?branch=master)](https://travis-ci.org/efacilitation/eventric-remote-socketio-endpoint)

This module is a Socket.IO/Websocket based adapter for the eventric remote endpoint interface.
Use it in combination with
[eventric-remote-socketio-client](https://github.com/efacilitation/eventric-remote-socketio-client)
in order to communicate with remote contexts via Websockets (client to server and server to server).


### API

#### initialize(options)

Initializes the endpoint. Returns a promise which resolves when the initialization is finished.
Two optional options may be passed into the function:

1. `ioInstance`: an instance of a Socket.IO server; if not given, a new one will be spawned automatically
2. `rpcRequestMiddleware(rpcRequest, socket)`: a middleware function for processing rpc requests;
the function must return a Promise which can reject in order to cancel the RPC request

Note: The middleware can be used to enrich data of RPC requests or to perform some kind of access control / authorization.

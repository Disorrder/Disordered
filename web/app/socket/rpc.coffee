disordered.service 'rpc', (socketService, $rootScope, notificationCenter) ->
    #TODO REWORK
    callId = 0
    cbsStack = {}

    showErr = {}

    debug = 1

    handler = null

    socketService.on 'rpcAnswer', (pack) ->
        blog pack.callId, 'RPC answ', pack.data if debug == 1
        cbsStack[pack.callId]? pack.data if pack.data?.err != true

        if pack.data.err == true
            if showErr[pack.callId] == true
                delete showErr[pack.callId]
                cbsStack[pack.callId]? pack.data
            else
                notificationCenter.addMessage
                    text: 'rpc_error_' + pack.data.code
                    error: if pack.data.code == 4 then false else true

        delete cbsStack[pack.callId]

        if handler == null
            handler = setTimeout () ->
                $rootScope.$apply()
                handler = null
            , 300
        true

    call = (method, data, cb, forceErrResult) ->
        if typeof data == 'function'
            cb = data
            data = {}

        if forceErrResult or data?.showErrors == true
            showErr[callId] = true

        pack =
            callId: callId
            method: method
            data: data || {}

        #if callId>20 then return
        cbsStack[callId] = cb if cb
        callId = 0 if callId > 1000
        socketService.emit 'rpcCall', pack

        blog pack.callId, 'RPC call', method, data if debug == 1

        callId++

    {
        call
    }





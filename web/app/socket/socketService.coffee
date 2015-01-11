disordered.service 'socketService', (env, localStorageService) ->
    socket = {}
    waitEmits = []
    waitOns = []

    connectCbs = []

    stored_sid = localStorageService.get 'sid'
    sid_validated = false

    $.getScript env.baseurl + 'socket.io/socket.io.js', () ->
        socket = io env.baseurl,
            secure: true
            transports: ['websocket']

        socket.on 'connect', () ->
            socket.emit 'uid', 'abc'

            for args in waitOns
                socket.on args.event, args.cb
            waitOns.length = 0

            socket.emit 'sid', stored_sid

    onConnect = (cb) =>
        connectCbs.push cb if cb?
        if socket.connected
            cb()

    _on = (e, cb) ->
        if !socket.connected
            waitOns.push 
                event: e
                cb: cb
        else
            socket.on e, cb

    _emit = (e, data) ->
        if !sid_validated #!socket.connected
            blog "_emit", e, "puted in wait stack"
            waitEmits.push 
                event: e
                data: data
        else
            socket.emit e, data

    _on 'sid', (sid) ->
        console.log 'sid'
        localStorageService.add 'sid', sid
        stored_sid = sid
        sid_validated = true

        for args in waitEmits
            socket.emit args.event, args.data

        waitEmits.length = 0

        for method in connectCbs
            method()


    {
        on: _on
        emit: _emit

        onConnect

    }


disordered.service 'socketAuth', ($state, socketService, rpc, localStorageService, account, notificationCenter) ->
    return # TODO AUTH

    # --- Init ---
    inited = false
    onInitStack = []

    session = {}

    processSession = (session_data) ->
        authed = session.authed
        updateObject session, session_data

        _doInit = ->
            inited = true
            for action in onInitStack
                action()
            onInitStack.length = 0

        if session_data.user_id+1 and session.authed == true
            account.update ->
                if authed != true # авторизовались
                    for action in onAuthStack
                        action()
                if authed == false # залогинились (вошли в систему)
                    for action in onLoginStack
                        action()

                if $state.current.name == 'login'
                    $state.go localStorageService.get('lastState') || 'timeline'

                _doInit()

        else
            if authed == true
                for action in onLogoutStack
                    action()
            $state.go 'login'
            _doInit()

    init = (cb) ->
        onInitStack.push cb if cb?
        if inited
            cb?()

    socketService.onConnect () ->
        rpc.call 'user.getSession', processSession

    socketService.on 'expired', () ->
        notificationCenter.addMessage
            text: 'logout_on_session_expire'
        fetchSession()

    # --- Auth ---

    onAuthStack = [] # срабатывает каждый раз при авторизации, в т.ч. при обновлении страницы
    onAuth = (method) -> onAuthStack.push method
    onLoginStack = [] # срабатывает только после входа в систему
    onLogin = (method) -> onLoginStack.push method

    accounts = []
    fetchAccounts = (cb) ->
        accounts.length = 0
        rpc.call 'user.getAccounts', (data) ->
            if data.err != true
                account.update
                    accounts: data
            cb? accounts

    onAuth fetchAccounts

    fetchSession = (cb) ->
        rpc.call 'user.getSession', (data) ->
            processSession data
            cb? data

    socketService.on 'user.update', (data) ->
        if data
            account.update data
        else
            fetchSession()

    authBuzzlike = (data, cb) ->
        rpc.call 'auth.login', data, (res) ->
            if res.err != true
                processSession res

            cb res

    # --- logout ---
    onLogoutStack = []

    logout = ->
        rpc.call 'auth.logout', processSession

    onLogout = (method) -> onLogoutStack.push method

    # --- getting news ---
    #onLogin ->
    #    rpc.call 'user.news', account.user

    # --- notify confirm email ---
    onAuth ->
        user = account.user
        if !user.registered
            if isEmail user.login
                message =
                    text: 'auth_confirmEmail'
                    data:
                        mail: user.login
            else
                message =
                    text: 'auth_setEmail'

            message.time = 10*SEC

            notificationCenter.addMessage message


    {
        session
        accounts

        init
        onAuth

        fetchAccounts
        fetchSession

        authBuzzlike

        logout
        onLogout
    }
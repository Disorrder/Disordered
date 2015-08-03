angular.module('app.auth').service('AuthService', ['__AuthService', (__AuthService) => { return new __AuthService() }]);
angular.module('app.auth').service('__AuthService', ['$q', 'localStorageService', 'Restangular','$window', 'UserService', '$rootScope', '$state', function($q, localStorageService, Restangular, $window, UserService, $rootScope, $state) {
    return class {
        constructor() {
            $rootScope.$on('user:logout', () => this.purge());

            Object.defineProperty($rootScope, 'isLogined', {
                get: () => { return this.isLogined }
            });
        }

        get isLogined() { 
            return UserService.currentUser.authed;
        }

        get accessToken() {
            return localStorageService.cookie.get('token');
        }

        setAccessToken(token) {
            localStorageService.cookie.set('token', token);
        }

        createAccessToken() {
            var token = this.accessToken;
            return 'Token ' + (token === 'undefined' ? '' : token);
        }

        createBasicToken(email, password) {
            return 'Basic ' + btoa($window.unescape(encodeURIComponent(email + ':' + password)));
        }

        authenticate(basicToken) {
            var headers = {
                'Authorization': basicToken,
            };

            return this.authRequest(null, headers);
        }

        authRequest(data = {}, headers) {
            return Restangular.all('authentication').post(data, {}, headers)
                .then((response) => this.authRequestCb(response));
        }

        authRequestCb(response) {
            $rootScope.$emit('remember:submit');
            this.setAccessToken(response.data.token);
            return response;
        }

        access(to) {
            var deferred = $q.defer(),
                token = this.accessToken,
                stateData = to ? $state.get(to).data : {};

            if (stateData.needAuth === undefined) { // always access
                deferred.resolve(HTTP_CODES.OK);
                return deferred.promise;
            }
            
            if (!token) {
                if (!stateData.needAuth) {
                    deferred.resolve(HTTP_CODES.OK);
                } else {
                    deferred.reject(HTTP_CODES.UNAUTHORIZED);
                }
                return deferred.promise;
            }

            this.authUser().then((user) => {
                if (user) {
                    if (!to || stateData.needAuth) {
                        deferred.resolve(HTTP_CODES.OK); // just user
                    } else if (!stateData.needAuth) {
                        deferred.reject(HTTP_CODES.FORBIDDEN);
                    }
                } else {
                    console.warn(`access(${to}): no user, uncatched error!`);
                    deferred.reject(HTTP_CODES.UNAUTHORIZED);
                }
            });

            return deferred.promise;
        }

        login(user) { // by credentians
            UserService.setCurrent({email: user.email});
            $rootScope.$emit('remember:set', user.email, user.password);
            var basicToken = this.createBasicToken(user.email, user.password);
            return this.authenticate(basicToken)
                .then(() => { return this.authUser() });
        }

        authUser() { // by token
            if (!this.accessToken) return false;
            this.setHeaders();

            return UserService.getCurrent().then((response) => {
                if (!this.isLogined) $rootScope.$emit('user:login');
                return response;
            }, (error) => {
                $rootScope.$emit('user:logout');
            });
        }

        setHeaders() {
            return Restangular.updateDefaultHeaders({
                'Authorization': this.createAccessToken()
            });
        }

        purge() {
            localStorageService.cookie.remove('token');
            Restangular.setDefaultHeaders({});
        }
    };
}]);

angular.module('app.auth', []).run(['$rootScope', '$state', 'AuthService', 'UserService', 'Restangular', ($rootScope, $state, AuthService, UserService, Restangular) => {
    $rootScope.$on('user:login', () => $rootScope.$emit('user:login.redirect'));
    $rootScope.$on('user:logout', () => $rootScope.$emit('user:logout.redirect'));

    $rootScope.$on('$stateChangeStart', (e, to, toParams, from, fromParams) => {
        to.base = to.name.split('.')[0];

        if (from.base && to.data) {
            if (to.data.needAuth === undefined) return;
            if (to.data.needAuth !== AuthService.isLogined) {
                e.preventDefault();
                if (to.data.needAuth === true) {
                    $rootScope.$emit('user:logout.redirect');
                    UserService.currentUser.authRedirectTo = [to.name, toParams];
                }
            }
        }
    });

    $rootScope.$on('$stateChangeError', (e, to, toParams, from, fromParams, error) => {
        if (error === HTTP_CODES.UNAUTHORIZED) {
            UserService.currentUser.authRedirectTo = [to.name, toParams];
            return $rootScope.$emit('user:logout');
        }
    });

    $rootScope.logout = () => {
        $rootScope.$emit('user:logout');
    };

    // expand Restangular

    window.rest = Restangular;
    Restangular.updateDefaultHeaders = (headers) => {
        headers = _.merge(Restangular.defaultHeaders, headers);
        return Restangular.setDefaultHeaders(headers);
    }
}]);

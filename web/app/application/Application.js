"use strict";

var app = angular.module('app', [
    'restangular',
    'ui.router',
    'LocalStorageModule',
    // our modules
    'app.auth',
    'app.history',
    'components'
]);

angular.module('components', [

]);

app.config(['RestangularProvider', '$urlRouterProvider', (RestangularProvider, $urlRouterProvider) => {
    RestangularProvider.setBaseUrl('http://localhost/api/v1/');
    RestangularProvider.setFullResponse(true);

    $urlRouterProvider.otherwise('/');
}]);

app.run(['$rootScope', '$state', 'AuthService', 'UserService', ($rootScope, $state, AuthService, UserService) => {
    $rootScope.$on('user:login.redirect', (e) => {
        var base = $state.current.base;
        // if (base !== 'app') $state.go.apply(null, UserService.currentUser.authRedirectTo || ['app.main']);
        delete UserService.currentUser.authRedirectTo;
    });

    $rootScope.$on('user:logout.redirect', (e) => {
        console.log('redir');
        var base = $state.current.base;
        // if (base !== 'guest') $state.go('guest.main');
    });

    $rootScope.$on('$stateChangeStart', (e, to, toParams, from, fromParams) => {
        console.log(from, to.name);
    });

}]);

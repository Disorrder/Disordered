angular.module('app').config(['$stateProvider', ($stateProvider) => {
    $stateProvider.state('guest', {
        url: '',
        abstract: true,
        templateUrl: 'application/pages/guest/abstract/template.html',
        data: {},
        resolve: {
            user: ['AuthService', (AuthService) => {
                return AuthService.access('guest');
            }]
        }
    })
}]);

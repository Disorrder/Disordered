angular.module('app').config(['$stateProvider', ($stateProvider) => {
    $stateProvider.state('guest.main', {
        url: '/',
        templateUrl: 'application/pages/guest/abstract/main/template.html'
    })
}]);

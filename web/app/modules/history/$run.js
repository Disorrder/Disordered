angular.module('app.history', []).run(['HistoryService', '$rootScope', (HistoryService, $rootScope) => {
    $rootScope.$on('$stateChangeStart', (e, to, toParams, from, fromParams) => {
        to.base = to.name.split('.')[0];
    });

    $rootScope.$on('$stateChangeSuccess', (e, to, toParams, from, fromParams) => {
        if (!to.abstract) this.push(to, toParams);
    });
}]);

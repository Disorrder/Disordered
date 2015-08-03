angular.module('app.history', []).service('HistoryService', ['__HistoryService', (__HistoryService) => { return new __HistoryService() }]);
angular.module('app.history').service('__HistoryService', ['$state', '$rootScope', ($state, $rootScope) => {
    class Class {
        constructor() {
            this.history = [];
            this.current = -1;
            this.hold = false;

            $state.history = this;
        }

        push(state, params) {
            if (this.hold) return;
            this.history.length = ++this.current;
            let page = {
                id: this.current,
                state: state,
                params: params
            };
            this.history.push(page);
        }

        getLast(base) {
            if (!base) return this.history[this.current-1];

            return _.find(this.history, (v) => {
                if (v.state.base === base && v.state.name !== base+'.main') return v;
            });
        }

        getById(id) {
            return _.find(this.history, {id});
        }

        back(base) {
            var prev = this.getLast(base);
            return this.go(prev);
        }

        go(page) {
            if (!page) return;
            this.hold = true;
            this.current = page.id;
            $state.go(page.state.name, page.params)
            this.hold = false;
            return true;
        }
    }

    return Class;
}]);

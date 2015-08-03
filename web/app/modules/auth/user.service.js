angular.module('app.auth').service('UserService', ['__UserService', (__UserService) => { return new __UserService() }]);
angular.module('app.auth').service('__UserService', ['Restangular','$window', '$rootScope', 'localStorageService', function(Restangular, $window, $rootScope, localStorageService) {
    const primaryKey = 'email'; // an user unique property

    class Class {
        constructor() {
            $rootScope.$on('user:login', () => this.currentUser.authed = true);
            $rootScope.$on('user:logout', () => this.purge());

            this.currentUser = {
                email: null,
                authed: false,
                get role() {
                    if (!this[primaryKey]) return 'guest';
                    return (this.userType === 'PeopleTest')? 'tester': 'staff';
                }
            };
            Object.fixProperties(this.currentUser);
        }

        getCurrent() {
            return Restangular.one('user', 'current').get().then((response) => {
                let user = response.data.plain();
                return this.setCurrent(user);
            }, (error) => {
                console.warn('no user!');
            });
        }      

        setCurrent(data) {
            return _.merge(this.currentUser, data);
        }

        getInfoByToken(authKey) {
            return Restangular.one('registration').get({authKey});
        }

        registerUser(user, headers) {
            return Restangular.all('registration').post(user, {}, headers);
        }

        saveData(data, hard = false) {
            var pk = this.currentUser[primaryKey],
                userData = localStorageService.get('userData:'+pk) || {};

            if (hard) _.each(data, (v, k) => { delete userData[k] });
            localStorageService.set('userData:'+pk, _.merge(userData, data));
            return userData;
        }

        loadData(key) {
            var pk = this.currentUser[primaryKey],
                data = localStorageService.get('userData:'+pk);
            return (key && data) ? data[key] : data;
        }

        removeData(key) {
            var data, pk = this.currentUser[primaryKey];
            if (key) {
                data = this.loadData();
                delete data[key];
                localStorageService.set('userData:'+pk, data);
            } else {
                localStorageService.remove('userData:'+pk);
            }
            return data;
        }

        purge() {
            var user = this.currentUser;
            user[primaryKey] = null;
            user.authed = false;
            Object.clear(user);
            return user;
        }
    }

    return Class;
}]);

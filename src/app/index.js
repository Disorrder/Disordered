import './utils.styl';
import './pages/style.styl';

import './vendor';
import './components';

window._app = {};

import Vue from 'vue';
import router from './router';
// import store from './store';

$.ajaxSetup({
    crossDomain: true,
    xhrFields: {
        withCredentials: true
    }
});

var app = new Vue({
    el: '#app',
    // store,
    router,
    data: {
        user: null,
    },
    methods: {
        getUser() {
            return $.get(config.api+'/user');
        }
    },
    created() {
        this.getUser().then((res) => {
            this.user = res;
        });
    }
});
window._app = app;

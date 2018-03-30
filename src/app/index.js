import './utils.styl';
import './pages/style.styl';

import './vendor';

import Vue from 'vue';
import router from './router';
// import store from './store';

$(() => {
    var app = new Vue({
        el: '#app',
        // store,
        router,
        data: {
            user: null,
        },
        created() {

        }
    });
    window.app = app;
});

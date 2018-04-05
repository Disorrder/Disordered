import './style.styl';

import Vue from 'vue';
Vue.component('navbar', {
    template: require('./template.pug')(),
    data() {
        return {
            menu: [
                {name: 'main', title: 'Главная'},
                {name: 'mood', title: 'Настроение'},
                {name: 'login', title: 'Войти'},
            ]
        }
    },
    mounted() {

    }
});

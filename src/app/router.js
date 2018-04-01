import Vue from 'vue';
import VueRouter from 'vue-router';
Vue.use(VueRouter);

export default new VueRouter({
    mode: 'history',
    routes: [
        {name: 'main', path: '/', component: require('app/pages/main').default},
        {name: 'mood', path: '/mood', component: require('app/pages/mood').default},
    ]
});

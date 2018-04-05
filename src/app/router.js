import Vue from 'vue';
import VueRouter from 'vue-router';
Vue.use(VueRouter);

var router = new VueRouter({
    mode: 'history',
    routes: [
        {name: 'main', path: '/', component: require('app/pages/main').default},
        {name: 'login', path: '/login', component: require('app/pages/login').default},
        {name: 'mood', path: '/mood', meta: {needAuth: true}, component: require('app/pages/mood').default},
    ]
});

export default router;

router.beforeEach((to, from, next) => {
    // TODO: get app
    console.log(to, to.matched, to.meta);
    if (to.meta.needAuth) {
        if (!window._app.user) {
            return next({path: '/login', query: { redirect: to.fullPath }});
        }
        // $.get(config.api+'/user')
        //     .then((res) => {
        //         console.log('isAuth', res);
        //         next();
        //     })
        //     .catch(() => {
        //         next({path: '/login', query: { redirect: to.fullPath }});
        //     })
        // ;
        // return;
    }

    next();
});

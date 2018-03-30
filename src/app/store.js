import Vue from 'vue';
import Vuex from 'vuex';
Vue.use(Vuex);

var module1 = {
    namespaced: true,
    state: {

    },
    mutations: {

    },
    actions: {

    }
};

var store = new Vuex.Store({
    modules: {
        module1
    }
});

export default store;

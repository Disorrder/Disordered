import './style.styl';

export default {
    template: require('./template.pug')(),
    data() {
        return {
            authData: {
                username: '',
                password: ''
            }
        }
    },
    computed: {

    },
    methods: {
        login() {

        }
    },
    created() {

    },
    mounted() {
        $('#login').focus();
    }
};

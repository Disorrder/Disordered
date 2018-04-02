var Router = require('koa-router');
var router = new Router();

let auth = require('./auth');
router.use('/auth', auth.routes(), auth.allowedMethods());

let user = require('./user');
router.use('/user', user.routes(), user.allowedMethods());

let mood = require('./mood');
router.use('/mood', mood.routes(), mood.allowedMethods());

router.get('/', (ctx, next) => {
    // ctx.router available
    ctx.body = 'Hi there';
});

module.exports = router;

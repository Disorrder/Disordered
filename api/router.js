var Router = require('koa-router');
var router = new Router();

{
    let route;
    route = require('./auth');
    router.use('/auth', route.routes(), route.allowedMethods());

    route = require('./user');
    router.use('/user', route.routes(), route.allowedMethods());

    route = require('./mood');
    router.use('/mood', route.routes(), route.allowedMethods());
}

router.get('/', (ctx, next) => {
    // ctx.router available
    ctx.body = 'Hi there';
});

module.exports = router;

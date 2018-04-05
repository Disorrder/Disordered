const User = require('./model');
const Router = require('koa-router');
var router = new Router();

router.post('/', async (ctx) => {
    // Create
    ctx.throw(403);
});

router.get('/', async (ctx) => {
    // console.log('current user', ctx.isAuthenticated());
    if (!ctx.isAuthenticated()) return ctx.throw(401);
    ctx.body = ctx.state.user;
});

router.get('/:id', async (ctx) => {
    var user = await User.findById(ctx.params.id);
    if (user) {
        ctx.body = user;
    } else {
        ctx.throw(404);
    }
});

router.put('/:id', async (ctx) => {
    var data = ctx.request.body
    var user = await User.findById(ctx.params.id);
    if (!user) return ctx.throw(404);

    if (data.access_token) user.access_token = data.access_token;
    if (data.message_token) user.message_token = data.message_token;

    user.save();
    ctx.body = user;
});

module.exports = router;

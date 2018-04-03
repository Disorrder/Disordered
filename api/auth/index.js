const User = require('../user/model');
var Router = require('koa-router');
var router = new Router();

const passport = require('koa-passport');

passport.serializeUser(function(user, done) {
    console.log('serialize user', user);
    done(null, user._id);
});

passport.deserializeUser(async function(id, done) {
    console.log('deserializeUser', id);
    try {
        var user = await User.findById(id);
        console.log('deserus', user);
        done(null, user);
    } catch(err) {
        done(err);
    }
});


{
    let route;
    route = require('./local');
    router.use('', route.routes(), route.allowedMethods());
}

router.post('/register', async (ctx) => {
    var data = ctx.request.body;

    if (data.password !== data.password_repeat) {
        ctx.throw(400, 'ERR_PASSWORDS_MISMATCH');
    }

    var user = new User(data);
    try {
        await user.save();
        await ctx.login(user);
    } catch(e) {
        if (e.code === 11000) {
            ctx.throw(400, 'ERR_USER_IS_ALREADY_EXISTS');
        } else {
            console.log(e);
            ctx.throw(500, e.message);
        }
        return;
    }
    ctx.body = user;
});

module.exports = router;

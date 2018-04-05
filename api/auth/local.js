const User = require('../user/model');
var Router = require('koa-router');
var router = new Router();

const passport = require('koa-passport');
const LocalStrategy = require('passport-local').Strategy;

passport.use(new LocalStrategy(function(username, password, done) {
    var field = ~username.indexOf('@') ? 'email' : 'username';
    User.findOne({[field]: username}).select('+password')
    .then((user) => {
        console.log('LS', user);
        if (!user) return done(null, false, 'ERR_INCORRECT_USERNAME');
        if (!user.verifyPassword(password)) return done(null, false, 'ERR_INCORRECT_PASSWORD');
        return done(null, user);
    })
    .catch((e) => done(e));
}));

router.post('/login', async (ctx) => {
    var data = ctx.request.body;
    var field = ~data.username.indexOf('@') ? 'email' : 'username';

    var user = await User.findOne({[field]: data.username}).select('+password');
    if (!user) return ctx.throw(403, 'ERR_INCORRECT_USERNAME');
    if (!user.verifyPassword(data.password)) return ctx.throw(401, 'ERR_INCORRECT_PASSWORD');

    // TODO: remove password
    ctx.login(user);
    ctx.body = user;
});

// some problem with error codes. If passport strategy fails, next middleware will not run
router.post('/__login', passport.authenticate('local'), async (ctx) => {
    var data = ctx.request.body;
    console.log('LOG', data, ctx, ctx.isAuthenticated(), ctx.state);
    ctx.body = ctx.state.user;
});

module.exports = router;

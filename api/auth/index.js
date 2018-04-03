const User = require('../user/model');
var Router = require('koa-router');
var router = new Router();

const passport = require('koa-passport');
const LocalStrategy = require('passport-local').Strategy;

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

router.post('/login', passport.authenticate('local'), async (ctx) => {
    var data = ctx.request.body;

    console.log('LOG', data, ctx, ctx.isAuthenticated(), ctx.state);
    // user.select('-password');
    ctx.body = data;
});

module.exports = router;

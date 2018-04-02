var Router = require('koa-router');
var router = new Router();

const passport = require('koa-passport');

passport.serializeUser(function(user, done) {
    
    done(null, user.id)
});

passport.deserializeUser(async function(id, done) {
  try {
    const user = await fetchUser()
    done(null, user)
  } catch(err) {
    done(err)
  }
});

router.get('/', (ctx, next) => {
    ctx.body = 'auth root';
});

router.post('/', (ctx, next) => {

    ctx.body = 'auth root';
});

module.exports = router;

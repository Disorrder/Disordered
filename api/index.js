const buildCfg = require('../buildconfig.json');
const cfg = require('./config');

var mongoose = require('mongoose');
mongoose.Promise = global.Promise;
mongoose.connect(cfg.db);

const Koa = require('koa');
const app = new Koa();

const session = require('koa-session');
app.keys = [cfg.secretKey];
app.use(session({}, app));

const bodyParser = require('koa-bodyparser');
app.use(bodyParser());

const passport = require('koa-passport');
app
    .use(passport.initialize())
    .use(passport.session())
;

const router = require('./router');
app
    .use(router.routes())
    .use(router.allowedMethods())
;

app.listen(buildCfg.api.port);

module.exports = app;

var Router = require('koa-router');
var router = new Router();

router.get('/', (ctx) => {
    ctx.body = 'mood root';
});

router.put('/', (ctx) => {
    
});

router.get('/:id', (ctx) => {

});

router.post('/:id', (ctx) => {

});

module.exports = router;

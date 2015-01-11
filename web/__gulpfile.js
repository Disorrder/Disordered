var gulp        = require('gulp'),
    log         = require('gulp-util').log,
    buffer      = require('gulp-util').buffer,
    jade        = require('gulp-jade'),
    stylus      = require('gulp-stylus'),
    coffee      = require('gulp-coffee'),
    webserver   = require('gulp-webserver'),
    fs          = require('fs-extra'),
    bower       = require('main-bower-files');

var path = {
        app: './app/',
        build: './.build/',
        excludePrefix: '__'
    };
    path.scripts     = path.app + '**/*.coffee';
    path.styles      = path.app + '**/*.styl';
    path.templates   = path.app + '**/*.jade';

var settings = {
    usemin: true // use .js.min if allowed instead .js
};

var files = {
    libs: {},
    app: {}
};

function getExt(str){
    var ext = str.match(/\.\w{1,}$/);
    if (!ext) return null;
    return ext[0].substr(1);
}

function src(source){
    if (typeof source != 'object') source = [source];
    source.push('!' + path.app + path.excludePrefix + '**/*'); // excludeFiles
    source.push('!' + path.app + '**/' + path.excludePrefix + '*'); // excludeFolders
    return gulp.src(source);
};

gulp.task('clean', function(){
    fs.removeSync(path.build);
    fs.mkdirpSync(path.build);
});

gulp.task('libs', function(){
    // Upgrade for bower plugin
    var i, f, minf, pos, ext, bowerFiles = bower(), libsFiles = [];
    for (i in bowerFiles){
        f = bowerFiles[i];
        pos = f.indexOf('bower_components');
        f = './' + f.substr(pos).replace(/\\/g, '/').replace('bower_components/', 'bower_components/**/');

        if (settings.usemin){
            if (!/\.min\.js$/.test(f) && /\.js$/.test(f)){ // ignores .min.js and allows .js
                minf = f.replace('.js', '.min.js');
                if ( fs.existsSync(minf.replace('/**', '')) ){ // if allowed .min.js file, build it instead .js
                    log("[Usemin] Found minificated: " + minf);
                    libsFiles.push(minf);
                    libsFiles.push(minf + '.map');
                    continue;
                }
            }
        }
        libsFiles.push(f);
    }

    return gulp.src(libsFiles, {base: './'})
        .pipe(gulp.dest(path.build))
        .pipe(buffer(function(err, libs){ // Sorting by extensions for auto-append in index.html
            var i, f, ext;
            for (i in libs){
                f = libs[i];
                ext = getExt(f.path)
                if (!ext){
                    log('[!WARN] File ' + f.path + 'have no extension.')
                    continue;
                }
                switch (ext) {
                    case 'eot': case 'svg': case 'ttf': case 'woff':
                        ext = 'fonts';
                }
                log('[Caching] ' + ext + ' - ' + f.path)
                if (!files.libs[ext]) files.libs[ext] = [];
                files.libs[ext].push(f);
            }
        }))
});

gulp.task('scripts', ['libs'], function() {
    return src(path.scripts)
        .pipe(coffee({bare: true}).on('error', log))
        .pipe(gulp.dest(path.build))
        .pipe(buffer(function(err, scriptFiles){
            files.app.js = scriptFiles;
        }))
});

gulp.task('styles', function(){
    src(path.styles)
        .pipe(stylus())
        //.pipe(gulp.dest(path.build))
        .pipe(buffer(function(err, files){
            var k, f, styles = path.build + 'styles/';
            fs.mkdirpSync(styles);
            fs.writeFileSync(styles + 'main.css', '');
            for (k in files){
                f = files[k];
                fs.appendFileSync(styles + 'main.css', '/* ' + f.relative + ' */\n' + f.contents + '\n');
            }
        }))
});

gulp.task('templates', function(){
    var index = path.app + 'index.jade';
    src([
        path.templates,
        '!' + index
    ])
        .pipe(jade())
        .pipe(gulp.dest(path.build))
});

gulp.task('index-html', ['scripts'], function(){
    var index = path.app + 'index.jade';
    return gulp.src(index)
        .pipe(jade({
            pretty: true,
            locals: {
                files: files
            }
        }))
        .pipe(gulp.dest(path.build))
});

gulp.task('files', function(){
    src([
        path.app + '**/*',
        '!' + path.app + '**/*.{coffee,styl,jade}'
    ])
        .pipe(gulp.dest(path.build))
});

gulp.task('watch', ['build'], function(){
    log('Watching files');
    gulp.watch(path.app+'*', ['build']);
});

gulp.task('webserver', ['build'], function(){ // instead 'watch'
    return gulp.src(path.build)
        .pipe(webserver({
            open: 'http://disordered.local:8000/',
            fallback: 'index.html',
            livereload: true
        }));
});

//define cmd line default task
gulp.task('build', ['scripts', 'styles', 'templates', 'files', 'index-html']);
gulp.task('clean-build', ['clean', 'build']);
gulp.task('default', ['build', 'watch', 'webserver']);

gulp        = require 'gulp'
log         = require('gulp-util').log
buffer      = require('gulp-util').buffer
jade        = require 'gulp-jade'
stylus      = require 'gulp-stylus'
coffee      = require 'gulp-coffee'
webserver   = require 'gulp-webserver'
filter      = require 'gulp-filter'
concat      = require 'gulp-concat'
wrap        = require 'gulp-wrap'
fs          = require 'fs-extra'
bowerFiles  = require 'main-bower-files'
eventStream = require 'event-stream'
tasks       = require './gulp-tasks.coffee'

path =
    app: './app/',
    build: './.build/',
    excludePrefix: '__'

path.scripts     = "#{path.app}**/*.coffee"
path.styles      = "#{path.app}**/*.styl"
path.templates   = "#{path.app}**/*.jade"
path.images      = "#{path.app}images/*.{png,svg,gif,jpg,jpeg}"

settings = # TODO in file
    usemin: true, # use .js.min if allowed instead .js
    host: 'http://disordered.local',
    port: '8000',
    livereload: true

tasks.add 'clean', ->
    #gulp.src('gulpfile.coffee').pipe(coffee({bare: true}).on('error', log)).pipe(gulp.dest path.build+'gulpfile/')
    fs.removeSync path.build
    fs.mkdirpSync path.build

# Command line commands
tasks.add 'default', ['clean', 'build', 'webserver']
tasks.add 'build'

# --- Webserver ---
tasks.add 'watch', ['build'], ->
    gulp.watch "#{path.app}**/*.*", ['build']

tasks.add 'webserver', ['build', 'watch'], ->
    gulp.src path.build
        .pipe webserver
            open: "#{settings.host}:#{settings.port}"
            fallback: 'index.html'
            livereload: settings.livereload





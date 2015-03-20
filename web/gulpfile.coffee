gulp        = require 'gulp'
log         = require('gulp-util').log
buffer      = require('gulp-util').buffer
jade        = require 'gulp-jade'
stylus      = require 'gulp-stylus'
coffee      = require 'gulp-coffee'
webserver   = require 'gulp-webserver'
filter      = require 'gulp-filter'
ignore      = require 'gulp-ignore'
concat      = require 'gulp-concat'
wrap        = require 'gulp-wrap'
fs          = require 'fs-extra'
File        = require 'vinyl'
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
    host: 'localhost',
    port: '18000',
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
            host: settings.host
            port: settings.port
            open: "http://#{settings.host}:#{settings.port}"
            fallback: 'index.html'
            livereload: settings.livereload


# --- BUILDER ---
getExt = (str) ->
    ext = str.match(/\.\w+$/)
    if !ext then return null
    ext[0].substr(1)

timer = 0
tasks.add 'timer.start', -> timer = Date.now()
    .includeTo 'build'

class Files
    @read: true
    @checkedFiles: {}

    @mapExt: (ext) ->
        switch ext
            when null, undefined then 'folder'
            when 'eot', 'svg', 'ttf', 'woff' then 'fonts'
            else return ext

    @cacheFiles: ->
        eventStream.map (file, cb) =>
            @cacheFile file
            cb null, file

    @cacheFile: (f) ->
        ext = @mapExt getExt f.path
        log "[Caching] #{ext} - #{f.path} = #{f.relative}"
        if !@files[ext] then @files[ext] = {}
        @files[ext][f.relative] = f

    @checkFiles: (full) ->
        eventStream.map (file, cb) =>
            if full then return cb null, file # skip checking, just return file

            rel = file.relative
            ts  = file.stat.mtime
            old_ts = @checkedFiles[rel]
            @checkedFiles[rel] = ts

            if !old_ts
                log "[Checking] New file #{rel}"
                return cb null, file

            if old_ts < ts
                log "[Checking] Update file #{rel}"
                return cb null, file

            cb()

    @build: (full = false) ->
        gulp.src @sources, {base: @base, read: @read}
            .pipe ignore.exclude "**/#{path.excludePrefix}*"
            .pipe @checkFiles full


class Libs extends Files
    @base: './'
    @files: {}
    @sources: bowerFiles()

    @build: ->
        super()
            .pipe @cacheFiles()
            .pipe gulp.dest path.build

    tasks.add 'Libs', => @build()
        .includeTo 'build'

class App extends Files
    @base: path.app
    @files: {}
    @sources: "#{path.app}**/*.*"

    tasks.add 'App', ['Libs']
        .includeTo 'build'

class Coffee extends App
    @sources: "#{path.app}**/*.coffee"

    @build: ->
        super()
            .pipe coffee({bare: true}).on('error', log)
            .pipe @cacheFiles()
            .pipe gulp.dest path.build

    tasks.add 'Coffee', => @build()
        .includeTo 'App'

class Stylus extends App
    @sources: "#{path.app}**/*.styl"

    @check: ->
        @build()
            .pipe stylus()
            #.pipe @cacheFiles()
            #.pipe gulp.dest path.build
            .pipe buffer (err, files) =>
                if files.length
                    tasks.get('main.css').enable()
                else
                    tasks.get('main.css').disable()

    @concat: ->
        @build(true)
            .pipe stylus()
            .pipe @cacheFiles()
            .pipe wrap '/* <%= file.relative %> */\n<%= contents %>'
            .pipe concat 'main.css'
            .pipe gulp.dest "#{path.build}styles/"

    tasks.add 'Stylus'
        .includeTo 'App'

    tasks.add 'Stylus.check', => @check()
        .includeTo 'Stylus'

    tasks.add 'main.css', 'Stylus.check', => @concat()
        .includeTo 'Stylus'

class Jade extends App
    @sources: ["#{path.app}**/*.jade", "!#{path.app}index.jade"]

    @build: ->
        super()
            .pipe jade()
            .pipe @cacheFiles()
            .pipe gulp.dest path.build

    @index: ->
        gulp.src "#{path.app}index.jade"
            .pipe jade
                pretty: true,
                locals:
                    libs: Libs.files
                    files: @files
            .pipe @cacheFiles()
            .pipe gulp.dest path.build

    tasks.add 'Jade', ['Coffee', 'Stylus'], => @build()
        .includeTo 'App'

    tasks.add 'index.html', ['App'], => @index()
        .includeTo 'build'


tasks.add 'timer.finish', ['index.html'], -> log "! Project was built in #{(Date.now() - timer) / 1000}s"
    .includeTo 'build'


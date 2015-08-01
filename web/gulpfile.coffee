gulp        = require 'gulp'
util        = require 'gulp-util'
log         = util.log
buffer      = util.buffer
webserver   = require 'gulp-webserver'
filter      = require 'gulp-filter'
ignore      = require 'gulp-ignore'
concat      = require 'gulp-concat'
wrap        = require 'gulp-wrap'
fs          = require 'fs-extra'
File        = require 'vinyl'
eventStream = require 'event-stream'
buffer      = require 'vinyl-buffer'
source      = require 'vinyl-source-stream'
bowerFiles  = require 'main-bower-files'
templateCache = require 'gulp-angular-templatecache'

coffee      = require 'gulp-coffee'
jade        = require 'gulp-jade'
stylus      = require 'gulp-stylus'
babel       = require 'gulp-babel'
jspm        = require 'jspm'

tasks       = require './gulp-tasks.coffee'

path =
    app: './app/',
    build: './.build/',
    excludePrefix: '__'

path.scripts     = "#{path.app}**/*.js"   # ?
path.styles      = "#{path.app}**/*.styl" # ?
path.templates   = "#{path.app}**/*.jade" # ?
path.assets      = 
    images: "#{path.app}**/*.{png,svg,gif,jpg,jpeg,ico}"
    fonts: "#{path.app}**/*.{eot,svg,ttf,woff,woff2}"

settings = # TODO in file
    usemin: true # use .js.min if allowed instead .js
    host: 'localhost'
    port: 18000
    livereload: true

tasks.add 'compile'
tasks.add 'clean', ->
    #gulp.src('gulpfile.coffee').pipe(babel().pipe(gulp.dest path.build+'gulpfile/')
    fs.removeSync path.build
    fs.mkdirpSync path.build

tasks.add 'settings:default', ->
    settings.buildmode = 'default'

tasks.add 'settings:build', ->
    settings.buildmode = 'build'

tasks.add 'settings:jspm', ->
    settings.buildmode = 'jspm'

# Command line commands to run
tasks.add 'default', ['settings:default', 'clean', 'compile', 'webserver']
tasks.add 'build',   ['settings:build',   'clean', 'compile']
tasks.add 'jspm',    ['settings:jspm',    'clean', 'compile', 'webserver']

# --- Webserver ---
tasks.add 'watch', ['compile'], ->
    gulp.watch "#{path.app}**/*.*", ['compile']

tasks.add 'webserver', ['compile', 'watch'], ->
    gulp.src path.build
    .pipe webserver
        host: '0.0.0.0' #settings.host
        port: settings.port
        open: "http://#{settings.host}:#{settings.port}"
        # fallback: 'index.html'
        livereload: settings.livereload


# --- BUILDER ---
getExt = (str) ->
    ext = str.match(/\.\w+$/)
    if !ext then return null
    ext[0].substr(1)

timer = 0
tasks.add 'timer.start', -> timer = Date.now()
    .includeTo 'compile'

class Files
    @read: true
    @checkedFiles: {}

    @mapExt: (ext) ->
        switch ext
            when null, undefined then 'folder'
            when 'eot', 'svg', 'ttf', 'woff', 'woff2' then 'fonts'
            else return ext

    @cacheFiles: ->
        eventStream.map (file, cb) =>
            @cacheFile file
            cb null, file

    @cacheFile: (f) ->
        ext = @mapExt getExt f.path
        log "[Caching] #{ext} - #{f.relative}"
        if !@files[ext] then @files[ext] = {}
        @files[ext][f.relative] = f

    @getCheckedFile: (rel) -> #TODO

    @checkFiles: (full) ->
        eventStream.map (file, cb) =>
            if full then return cb null, file # skip checking, just return file

            rel = file.relative
            ts  = file.stat.mtime
            old_ts = @checkedFiles[rel]?.ts
            checked = @checkedFiles[rel] = {
                ts: ts
            }

            # TODO make includesIn for each file and update them if necessary
            ext = @mapExt getExt file.path
            if (ext != 'js')
                reg = /include\s+([\"\'\w\.\/]+)/gm
                includes = file.contents.toString().match(reg)
                if includes
                    log "[Checking]", "Force update".green.underline, "#{rel}"
                    return cb null, file
            # ------

            if !old_ts
                log "[Checking]", "New file".green, "#{rel}"
                return cb null, file

            if old_ts < ts
                log "[Checking]", "Update file".yellow, "#{rel}"
                return cb null, file

            cb()

    @getFiles: (full = false) ->
        gulp.src @sources, {base: @base, read: @read}
            .pipe ignore.exclude "**/#{path.excludePrefix}*"
            .pipe @checkFiles full


class App extends Files
    @base: path.app
    @files: {}
    @sources: "#{path.app}**/*.*"

    errors = []
    @logErrorStatus: ->
        if errors.length
            status = "With #{errors.length} error"
            if errors.length > 1 then status += 's'
            log status.red.underline
        else
            status = "Without errors"
            log status.green.underline
        return !!errors.length

    @cleanErrors: -> errors.length = 0

    @error: (err, type) ->
        errors.push err
        log "\n--- [#{type} error] ---\n".red, err.toString(), "\n------------".red
        @emit 'end'

    tasks.add 'App'
        .includeTo 'compile'

class Assets extends App
    @build: ->
        logStr = "Moving assets: "
        for k, v of path.assets
            logStr += "#{k}, "
            gulp.src(v)
                .pipe @cacheFiles()
                .pipe gulp.dest path.build
        log logStr.substring(0, logStr.length - 2)

    tasks.add 'Assets', => @build()
        .includeTo 'App'

class Bower extends App
    @base: './'
    @files: {}
    @sources: bowerFiles()

    @build: ->
        if settings.buildmode in ['jspm'] then return
        @getFiles()
            .pipe @cacheFiles()
            .pipe gulp.dest path.build

    tasks.add 'Bower', => @build()

class ES6 extends App
    @sources: "#{path.app}**/*.js"
    @error: (e) -> super(e, 'Babel')

    @compile: ->
        @getFiles()
            .pipe babel()
            .on 'error', @error
            .pipe @cacheFiles()

    @build: ->
        @compile()
            .pipe gulp.dest path.build

    @jspmBuild: ->
        @compile()
            .pipe gulp.dest path.build

        gulp.src('./jspm_packages/**/*.*')
            .pipe gulp.dest "#{path.build}jspm_packages/"
        gulp.src('./config.js')
            .pipe gulp.dest path.build

    @SFXbuild: ->
        jspm.bundleSFX("#{path.app}application/Application", "#{path.build}scripts/app.js", { sourceMaps: false })

    tasks.add 'ES6', ['Bower'], =>
        switch settings.buildmode
            when 'default', 'build' then @build()
            when 'jspm' then @jspmBuild()
    .includeTo 'App'

class Coffee extends App
    @sources: "#{path.app}**/*.coffee"
    @error: (e) -> super(e, 'Coffee')

    @compile: ->
        @getFiles()
            .pipe coffee({bare: true}).on('error', @error)
            .pipe @cacheFiles()

    @build: ->
        @compile()
            .pipe gulp.dest path.build

    tasks.add 'Coffee', ['Bower'], => @build()
        .includeTo 'App'

class Stylus extends App
    @sources: "#{path.app}**/*.styl"
    @error: (e) -> super(e, 'Stylus')

    @build: ->
        @getFiles()
            .pipe stylus()
            .on 'error', @error
            .pipe @cacheFiles()
            .pipe gulp.dest path.build

    @check: ->
        @getFiles()
        .pipe @cacheFiles()
        .pipe buffer (err, files) =>
            if files.length
                tasks.get('main.css').enable()
            else
                tasks.get('main.css').disable()

    @concat: ->
        @getFiles(true)
            .pipe stylus()
            .on 'error', @error
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
    @error: (e) -> super('Stylus', e)

    @build: ->
        @getFiles()
            .pipe jade().on 'error', @error
            .pipe @cacheFiles()
            .pipe gulp.dest path.build

    @check: ->
        @getFiles()
            .pipe @cacheFiles()
            .pipe buffer (err, files) =>
                if files.length
                    tasks.get('template-cache').enable()
                else
                    tasks.get('template-cache').disable()

    @templateCache: ->
        @getFiles(true)
            .pipe jade().on 'error', @error
            .pipe templateCache('templates.js', {
                base: path.app
            })
            .pipe ES6.cacheFiles()
            .pipe gulp.dest "#{path.build}"

    @index: ->
        gulp.src "#{path.app}index.jade"
            .pipe jade
                pretty: true,
                locals:
                    buildmode: settings.buildmode
                    files: @files
                    bower: Bower.files
            .on 'error', @error
            .pipe @cacheFiles()
            .pipe gulp.dest path.build


    tasks.add 'Jade', ['ES6', 'Stylus'], => @build()
        .includeTo 'App'

    # tasks.add 'template-cache', ['Jade'], => @templateCache()
    #     .includeTo 'App'

    tasks.add 'index.html', ['App'], => @index()
        .includeTo 'compile'


tasks.add 'timer.finish', ['index.html'], ->
    log "Project was built in".yellow.underline, "#{(Date.now() - timer) / 1000}s".green.underline
    App.logErrorStatus()
    App.cleanErrors()
    log "\n\n"
.includeTo 'compile'

##################
#   HOW TO RUN   
##################
# Common:
# npm install
# npm install gulp -g
##################
# Simple build:
# bower install
# gulp --silent (runs with webserver)
# gulp build (just build)
# ----------------
# Run with jspm:
# npm install jspm -g
# jspm init
# jspm install
# gulp jspm
##################

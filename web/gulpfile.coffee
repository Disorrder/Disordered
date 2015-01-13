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
    host: 'http://disordered.local',
    port: '8000',
    livereload: true

tasks.add 'clean', ->
    #gulp.src('gulpfile.coffee').pipe(coffee({bare: true}).on('error', log)).pipe(gulp.dest path.build+'gulpfile/')
    fs.removeSync path.build
    fs.mkdirpSync path.build

# Command line commands
tasks.add 'default', ['clean', 'build'] #, 'webserver']
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


# --- BUILDER ---
getExt = (str) ->
    ext = str.match(/\.\w+$/)
    if !ext then return null
    ext[0].substr(1)

class Files
    @read: true
    @changedFiles: []
    @check: -> true

    @build: (full = false) ->
        stream = gulp.src @sources, {base: @base, read: @read}
            .pipe ignore.exclude "**/#{path.excludePrefix}*"

        if !full and @changedFiles.length then stream.pipe ignore.include @changedFiles
        if @filter then stream.pipe @filter
        stream


class Libs extends Files
    @base: './'
    @files: {}
    @sources: bowerFiles()

    @build: ->
        super()
            .pipe gulp.dest path.build
            #.pipe @cacheFiles()

    tasks.add 'libs', => @build()
        .includeTo 'build'

class App extends Files
    @base: path.app
    @files: {}
    @sources: "#{path.app}**/*.*"

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

class Coffee extends App
    @sources: "#{path.app}**/*.coffee"

    @build: ->
        super()
            .pipe coffee({bare: true}).on('error', log)
            .pipe @cacheFiles()
            .pipe gulp.dest path.build

    tasks.add 'Coffee', => @build()
        .includeTo 'build'

class Stylus extends App
    @sources: "#{path.app}**/*.styl"

    @check: ->
        @build()
            .pipe stylus()
            #.pipe @cacheFiles()
            #.pipe gulp.dest path.build
            .pipe buffer (err, files) =>
                #return true
                if files.length
                    tasks.get('main.css').enable()
                else
                    tasks.get('main.css').disable()

    @concat: ->
        @build()
            .pipe stylus()
            .pipe @cacheFiles()
            .pipe wrap '/* <%= file.relative %> */\n<%= contents %>'
            .pipe concat 'main.css'
            .pipe gulp.dest "#{path.build}styles/"

    tasks.add 'Stylus'

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

    tasks.add 'Jade', ['Coffee', 'Stylus'], => @build()
        .includeTo 'build'

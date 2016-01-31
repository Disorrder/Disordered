cfg         = require './gulpconfig.json'

_           = require 'lodash'
path        = require 'path'
fs          = require 'fs-extra'
hashFiles   = require 'hash-files'
argv        = require('optimist').argv
colors      = require 'colors'
chokidar    = require 'chokidar'
gulp        = require 'gulp'
concat      = require 'gulp-concat'
filter      = require 'gulp-filter'
ignore      = require 'gulp-ignore'
tasks       = require 'gulp-tasks-mng'
util        = require 'gulp-util'
wrap        = require 'gulp-wrap'
hash        = require 'gulp-hash'
git         = require 'gulp-git'
# watch       = require 'gulp-watch'
webserver   = require 'gulp-webserver'
eventStream = require 'event-stream'
merge       = require 'merge-stream'
templateCache = require 'gulp-angular-templatecache'
# compilers
jade        = require 'gulp-jade'
stylus      = require 'gulp-stylus'
nib         = require 'nib'
babel       = require 'gulp-babel'
eslint      = require 'gulp-eslint'

tasks.add 'compile'
tasks.add 'clean', ->
    Cache.purge()
    fs.ensureDirSync cfg.path.build
    fs.readdirSync(cfg.path.build).map (file) ->
        fs.removeSync path.join cfg.path.build, file

tasks.add 'cfg:default', -> # TODO: think about argv
    cfg.buildmode = 'default'
    if typeof argv.mode is 'string' then cfg.buildmode = argv.mode
    cfg.appConfig = if _.isString argv.appconfig then argv.appconfig else 'pmi'

tasks.add 'cfg:build', ->
    cfg.buildmode = 'build'
    cfg.appConfig = if _.isString argv.appconfig then argv.appconfig else 'pmi'

# Command line commands to run
tasks.add 'default', ['cfg:default', 'clean', 'compile', 'webserver']
tasks.add 'build',   ['cfg:build',   'clean', 'compile']

# --- Webserver ---
tasks.add 'watch', ['compile'], ->
    paths = [
        path.join(cfg.path.app, '**/*.*'),
        path.join(cfg.path.bower, 'bower.json')
    ]

    chokidar.watch paths, {ignoreInitial: true}
        .on 'add',    (f) -> util.log '[Watcher] Add'.green, f; watcher.add f
        .on 'change', (f) -> util.log '[Watcher] Change'.yellow, f
        .on 'unlink', (f) -> util.log '[Watcher] Unlink'.red, f; watcher.remove f; tasks.run 'clean'

    watcher = gulp.watch paths, ['compile']

tasks.add 'webserver', ['compile', 'watch'], ->
    cfg.webserver.open = "http://#{cfg.webserver.hostname}:#{cfg.webserver.port}"
    gulp.src cfg.path.build
        .pipe webserver cfg.webserver

# --- LIBS FOR BUILD ---

timer = 0
tasks.add 'timer.start', -> timer = Date.now()
    .includeTo 'compile'

class Cache
    @files: []

    @extendFile: (file) ->
        file.url = '/' + file.relative.replace(/\\/g, '/')
        file.extname = path.extname file.path
        file.ext = file.extname.substr(1)
        file

    @extendFiles: ->
        eventStream.map (file, cb) =>
            cb null, @extendFile file

    @cacheFile: (file, group = 'default') ->
        @extendFile file
        file.group = group
        cachedFile = _.find @files, {relative: file.relative}
        if cachedFile
            if !argv.silent then util.log "[Cache] update", file.ext, "-", file.relative
            @files[@files.indexOf(cachedFile)] = file
        else
            if !argv.silent then util.log "[Cache] add", file.ext, "-", file.relative
            @files.push file
        file

    @cacheFiles: (group) ->
        eventStream.map (file, cb) =>
            cb null, @cacheFile file, group

    @deleteFile: (path) ->
        if _.isObject path then path = path.relative
        @files = _.reject @files, {relative: path}

    @filterByExt: (ext) ->
        @files.filter (file) -> file.ext == ext || !ext

    @purge: -> @files.length = 0

# --- BUILDER ---

class Files
    @read: true
    @souces: []
    @getSources: -> @sources

    @error: (e, type="Compile") ->
        E = new Error e
        util.log "\n--- [#{type} error] ---\n".red, E.toString(), "\n------------".red
        @emit 'end'

    @cacheFiles: (group) -> Cache.cacheFiles group

    @getAllFiles: ->
        gulp.src @getSources(), {base: @base, read: @read}

    @getFiles: ->
        gulp.src @getSources(), {base: @base, read: @read}
            .pipe ignore.exclude "**/#{cfg.excludePrefix}*" # excludes files
            .pipe ignore.exclude "**/#{cfg.excludePrefix}*/**/*" # and folders

class App extends Files
    @base: cfg.path.app

    @run: (cb) ->
        switch cfg.buildmode
            when 'default' then @compile? cb
            when 'build' then @build? cb

    @task: tasks.add 'App', => @run()
        .includeTo 'compile'

class Bower extends App
    @base: cfg.path.bower
    @sources: []

    @fetchMain: ->
        `var ignore` # conflict with lib name
        bowerFile = fs.readJsonSync path.join cfg.path.bower, 'bower.json'
        deps = _.assign bowerFile.dependencies, bowerFile.devDependencies
        main = []
        ignore = []
        for lib, v of deps
            libBower = fs.readJsonSync path.join cfg.path.bower, 'bower_components', lib, '.bower.json'
            libBowerCfg = cfg.bowerOverrides[lib]
            _main = if libBower.main then [].concat libBower.main else [] #ensure array

            if libBowerCfg
                if libBowerCfg.main
                    _main = [].concat libBowerCfg.main #ensure array
                else
                    _main = _main.concat libBowerCfg.add if libBowerCfg.add
                    _ignore = libBowerCfg.ignore
                    if _ignore then ignore.concat _ignore.map (file) -> path.join cfg.path.bower, 'bower_components', lib, file

            main = main.concat _main.map (file) -> path.join cfg.path.bower, 'bower_components', lib, file

        main = main.filter (file) ->
            if !fs.existsSync(file) then util.log "File is not exist!".red, file
            if file in ignore then return false
            true

        @sources = main

    @compile: (cb) ->
        @fetchMain()
        @getAllFiles()
            .pipe @cacheFiles('bower')
            .pipe gulp.dest cfg.path.build

    @build: ->
        jsFilter = filter "**/*.js", {restore: true}
        @fetchMain()
        @getAllFiles()
            .pipe jsFilter
            .pipe wrap "/* --- <%= file.relative %> --- */\n<%= contents %>"
            .pipe concat path.join 'bower_components', 'libs.js'
            .pipe hash {hashLength: 6}
            .pipe jsFilter.restore
            .pipe @cacheFiles('bower')
            .pipe gulp.dest cfg.path.build

    @task: tasks.add 'Bower', => @run()
        .includeTo 'App'

class Config extends App # TODO: such wow, such refactor
    @compile: (cb) ->
        appConfigName = cfg.appConfig
        # util.log '!!!!!!!!!!!!!!!!!!!' + appConfigName
        if !appConfigName then return false # TODO: check for default.json and extend merge them

        appConfigFile = fs.readFileSync path.join cfg.path.app, 'application', 'system', '__config.js'
        appConfigFile = appConfigFile.toString()
        appConfig = fs.readJsonSync path.join cfg.path.app, 'config', appConfigName+'.json'
        appConfig = JSON.stringify(appConfig, null, 4)
        appConfigOutput = path.join cfg.path.app, 'application', 'system', 'built_config.js'
        fs.writeFileSync appConfigOutput, "#{appConfigFile}_.extend(APP_CONFIG, #{appConfig});"

    @build: @compile

    @task: tasks.add 'Config', => @run()
        # .includeTo 'App'

class Sources extends App
    @filters: null
    @sources: [path.join(cfg.path.app, "**/*.*"), "!"+path.join(cfg.path.app, cfg.filters.index)]
    @getSources: -> @sources.concat cfg.ignore.map (v) -> "!"+v

    @compile: (cb) ->
        if argv.silent then util.log "Compiling Sources".yellow.underline
        @filters = _.mapValues cfg.filters, (v) -> filter v, {restore: true}
        @getFiles()
            .pipe @filters.scripts
            .pipe babel()
            .on 'error', @error
            .pipe @filters.scripts.restore

            .pipe @filters.styles
            .pipe stylus {use: nib(), import: ['nib']} #? use and import?
            .on 'error', @error
            .pipe @filters.styles.restore

            .pipe @filters.templates
            .pipe jade({basedir: @base}).on 'error', @error
            .pipe @filters.templates.restore

            .pipe @cacheFiles()
            .pipe gulp.dest cfg.path.build

    @build: ->
        @filters = _.mapValues cfg.filters, (v) -> filter v, {restore: true}
        @getFiles()
            .pipe @filters.scripts
            .pipe wrap "/* --- <%= file.relative %> --- */\n<%= contents %>"
            .pipe concat 'scripts.js'
            .pipe hash {hashLength: cfg.hashLength}
            .pipe babel()
            .on 'error', @error
            .pipe @filters.scripts.restore

            .pipe @filters.styles
            .pipe wrap '/* --- <%= file.relative %> --- */\n@import "<%= file.relative %>"'
            .pipe concat 'styles.styl'
            .pipe hash {hashLength: cfg.hashLength}
            .pipe stylus {use: nib(), import: ['nib'], compress: false}
            .on 'error', @error
            .pipe @filters.styles.restore

            .pipe @filters.templates
            .pipe jade({basedir: @base}).on 'error', @error
            # .pipe templateCache('templates.js', {
            #     base: cfg.path.build
            # })
            .pipe @filters.templates.restore

            .pipe @cacheFiles()
            .pipe gulp.dest cfg.path.build

    @task: tasks.add 'Sources', => @run()
        .include 'Bower'
        .includeTo 'App'

class Lint extends Sources
    @filters: null

    @compile: ->
        @filters = _.mapValues cfg.filters, (v) -> filter v, {restore: true}
        @getFiles()
            .pipe @filters.scripts
            .pipe eslint
                rules:
                    strict: [2, "global"]
                useEslintrc: true
            .pipe eslint.formatEach 'compact', process.stderr
            .pipe @filters.scripts.restore

    @build: -> true

    @task: tasks.add 'Lint', ['Bower', 'Sources'], => @run()
        # .includeTo 'App'

    if argv.silent then @task.disable()

# --- git tasks ---
tasks.add 'Git.rev', (cb) -> # TODO: pref use git and run before building
    cfg.version = {}

    getTime = (ts) ->
        d = new Date(ts)
        date = d.toLocaleDateString()
        time = d.toTimeString().split(' ')[0]
        "#{date} #{time}"

    git.revParse {args:'--short HEAD'}, (err, hash) ->
        if err # not a git repo
            cfg.version.ts = Date.now()
            cfg.version.time = getTime cfg.version.ts
            hashFiles {files: [cfg.path.app]}, (err, hash) ->
                cfg.version.rev = hash.substr(-cfg.hashLength)
                cb()

        else
            cfg.version.rev = hash
            git.exec {args: 'log -1 --pretty=format:%ct'}, (err, stdout) ->
                cfg.version.ts = stdout
                cfg.version.time = getTime cfg.version.ts
                cb()

.includeTo 'App'
# ---

class Index extends App
    @compile: ->
        gulp.src path.join cfg.path.app, cfg.filters.index
            .pipe jade
                pretty: true,
                locals:
                    buildmode: cfg.buildmode
                    files: Cache
                    version: cfg.version
            .on 'error', @error
            .pipe @cacheFiles()
            .pipe gulp.dest cfg.path.build

    @build: @compile

    @task: tasks.add 'Sources:index', => @run()
        .include 'Sources'
        .includeTo 'App'

tasks.add 'timer.finish', -> util.log "Project was built in", "#{(Date.now() - timer) / 1000}s", "\n\n"
    .include 'Sources:index'
    .includeTo 'compile'

# console.log tasks.get 'default'
# gulp.task 'default', () -> util.log 'OLOLOSHA'
# tasks.setGulp gulp
# tasks.add 'default', () -> util.log 'OLOLOSHA'

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
##################

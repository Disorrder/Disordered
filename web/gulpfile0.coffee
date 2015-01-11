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

gulp.task 'clean', ->
    #gulp.src('gulpfile.coffee').pipe(coffee({bare: true}).on('error', log)).pipe(gulp.dest path.build+'gulpfile/')
    fs.removeSync path.build
    fs.mkdirpSync path.build

# Command line commands
gulp.task 'build', ['build.libs', 'build.app'], -> App.buildIndex()
gulp.task 'default', ['clean', 'build', 'webserver']

# --- Webserver ---
gulp.task 'watch', ['build'], ->
    gulp.watch "#{path.app}**/*.*", ['build']

gulp.task 'webserver', ['build', 'watch'], ->
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
    @indexBuilt: false
    @mapExt: (ext) ->
        switch ext
            when null, undefined then 'folder'
            when 'eot', 'svg', 'ttf', 'woff' then 'fonts'
            else return ext

    @sources: (src) ->
        src = [
            "!#{path.app}#{path.excludePrefix}**/*", # exclude folders with prefix
            "!#{path.app}**/#{path.excludePrefix}*" # exclude files with prefix
        ].concat src

    @check: ->
        eventStream.map (file, cb) =>
            relative = file.relative # .replace /\\/g, '/'

            ext = @mapExt getExt relative
            relative = relative.replace /\.(\w+)$/, (str, $0) ->
                switch $0
                    when 'coffee' then return '.js'
                    when 'styl' then return '.css'
                    when 'jade' then return '.html'
                    else return str

            cachedFile = @files[ext]?[relative]
            if !cachedFile
                log "[Cache] File is not cached: <#{relative}>"
                if ext == 'js' then @indexBuilt = false
                return cb null, file

            if cachedFile.stat.mtime < file.stat.mtime
                log "[Cache] Changed file <#{relative}>"
                if relative == 'index.html' then @indexBuilt = false
                return cb null, file
            cb()

    @cacheFiles: ->
        eventStream.map (file, cb) =>
            @cacheFile file
            cb null, file

    @cacheFile: (f) ->
        ext = @mapExt getExt f.path
        log "[Caching] #{ext} - #{f.path} = #{f.relative}"
        if !@files[ext] then @files[ext] = {}
        @files[ext][f.relative] = f

    @build: (filesForBuild) ->
        gulp.src @sources(filesForBuild), {base: @base}

    @refresh: ->
        filesSrc = []
        gulp.src @sources(), {base: @base, read: false}
            .pipe @check()
            .pipe buffer (err, files) =>
                for f in files
                    filesSrc.push f.path
            .on 'end', => @build filesSrc

class Libs extends Files
    @base: './'
    @files: {} # [extension][relative]: Vinyl File()

    @sources: (filesForBuild) ->
        if filesForBuild
            if filesForBuild.length == 0 then return ''
            if filesForBuild.length then return super filesForBuild
        #Upgrade for bower plugin
        libsFiles = []
        for f in bowerFiles()
            pos = f.indexOf 'bower_components'
            f = './' + f.substr(pos).replace(/\\/g, '/')

            if settings.usemin
                if !/\.min\.js$/.test(f) and /\.js$/.test(f) # ignores .min.js and allows .js
                    minf = f.replace '.js', '.min.js'
                    if fs.existsSync minf  # if allowed .min.js file, build it instead .js
                        #log "[Usemin] Found minificated: #{minf}"
                        libsFiles.push minf
                        libsFiles.push minf+'.map'
                        continue
            libsFiles.push f
        super libsFiles

    # tasks
    @build: (filesForBuild) =>
        super(filesForBuild)
            .pipe gulp.dest path.build
            .pipe @cacheFiles()

    # declare
    gulp.task 'build.libs', => @build()
    gulp.task 'refresh.libs', => @refresh()

class App extends Files
    @base: path.app
    @files: {} # [extension][relative]: Vinyl File()
    @sources: ["#{path.app}**/*.*"]

    @sources: (filesForBuild) ->
        if filesForBuild
            if filesForBuild.length == 0 then return ''
            if filesForBuild.length then return super filesForBuild
        super ["#{path.app}**/*.*"]

    # tasks
    @build: (filesForBuild) ->
        coffeeFilter = filter ['**/*.coffee']
        stylFilter   = filter ['**/*.styl']
        jadeFilter   = filter ['**/*.jade', '!index.jade']
        filesFilter  = filter ['**/*.*', '!**/*.{coffee,styl,jade}']

        super(filesForBuild)
            .pipe coffeeFilter
            .pipe coffee({bare: true}).on('error', log)
            .pipe @cacheFiles()
            .pipe gulp.dest path.build
            .pipe coffeeFilter.restore() #end: true

            .pipe stylFilter
            .pipe stylus()
            #.pipe gulp.dest path.build
            .pipe buffer (err, files) =>
                result = ''
                for f in files
                    @cacheFile f
                    result += "/* #{f.relative} */\n#{f.contents}"
                fs.outputFileSync "#{path.build}styles/main.css", result
            .pipe stylFilter.restore end: true #wtf??

            .pipe jadeFilter
            .pipe jade()
            .pipe @cacheFiles()
            .pipe gulp.dest path.build
            .pipe jadeFilter.restore() #end: true

            .pipe filesFilter
            .pipe @cacheFiles()
            .pipe gulp.dest path.build
            #.pipe filesFilter.restore end: true

    @buildIndex: =>
        if @indexBuilt then return
        log "Building index.html!"
        @indexBuilt = true
        gulp.src path.app+'index.jade'
            .pipe jade
                pretty: true,
                locals:
                    libs: Libs.files
                    files: @files
            .pipe @cacheFiles()
            .pipe gulp.dest path.build

    # declare
    gulp.task 'build.app', ['build.libs'], => @build()
    gulp.task 'refresh.app', ['refresh.libs'], => @refresh()

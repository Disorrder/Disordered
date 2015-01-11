sys      = require 'sys'
fs       = require 'fs-extra'
http     = require 'http'
url      = require 'url'
coffee   = require 'coffee-script'
stylus   = require 'stylus'
jade     = require 'jade'
nib      = require 'nib'

require './../helpers.coffee'

charset = "utf8"

appRoot = "../app"
sourceRoot = "../sources"
publicRoot = "../public"
pagesDir = "/pages"

routes =
    "": "index" #test

files = {}

# --- calling routes definition ---
checkRoute = (req, res)->
    url_parts = url.parse req.url
    route = url_parts.pathname.substr 1
    file = "#{publicRoot}/#{route}"
    if fs.existsSync file
        log "existing file!", file
        readFile file, res
    else
        file = routes[route] or routes['404']
        if file
            file = sourceRoot + file
            readFile file, res
    true

readFile = (file, res) ->
    ext = getExtension file
    path = file.split('.'+ext)[0]
    log file, path, ext

    read = -> fs.readFile file, (err, data) ->
        if !err
            res.end data
        else
            log "ERR", err
            res.end err

    switch ext #TODO CONTENT-types
        when 'js'
            res.setHeader 'content-type', 'text/javascript'
            read()
        when 'html'
            res.setHeader 'content-type', 'text/html'
            read()
        when 'css'
            res.setHeader 'content-type', 'text/css'
            read()
        when 'coffee'
            res.setHeader 'content-type', 'text/javascript'
            read()
        when 'jade'
            res.setHeader 'content-type', 'text/html'
            read()
        when 'stylus'
            res.setHeader 'content-type', 'text/css'
            read()
        else
            read()

    #res.end file

compileFile = (path, cb) ->
    true

getExtension = (fname) -> fname.split('.').pop()

runServer = ->
    http.createServer(checkRoute).listen 80 #,'localhost'
    sys.puts 'Server running at http://127.0.0.1:80/'
# -----------

getFiles = (path=sourceRoot) ->
    log path
    if path[0] == '/' then path = sourceRoot + path
    log path
    result = {}
    list = fs.readdirSync path
    for file in list
        if file[0] == file[1] == '_' then continue # пропускаем сборку, если имя файла начинается с двух подчёркиваний
        log 'file', file
        filePath = "#{path}/#{file}"
        stat = fs.statSync filePath
        if stat.isDirectory()
            log "dir", filePath
            if !result.dir then result.dir = []
            result.dir.push
                name: file
                path: filePath
        else
            ext = getExtension file
            if !result[ext] then result[ext] = []
            result[ext].push
                name: file
                path: filePath
    result

getApplicationFiles = (path=sourceRoot) ->
    types = getFiles path
    log 'path', path
    for type of types
        if type == 'dir'
            for file in types[type]
                getApplicationFiles file.path
            continue
        if !files[type] then files[type] = []
        files[type] = files[type].concat types[type]

getPages = () ->
    files.pages = []
    pages = getFiles(pagesDir).dir
    for pageDir in pages
        pageFiles = getFiles(pageDir.path)
        log "PT", pageFiles, pageDir
        page =
            name: pageDir.name

        # Записываем путь шаблона (+ костыль для хтмл)
        templateType = 'html' if pageFiles.html
        templateType = 'jade' if pageFiles.jade
        if pageFiles[templateType]?.length
            if pageFiles[templateType].length == 1
                page.template = pageFiles[templateType][0].path
            else
                template = findObjectByFields pageFiles.jade, {name: "template.#{templateType}"}
                page.template = template.path

        # Записываем путь контроллера (+ костыль для js)
        controllerType = 'js'     if pageFiles.js
        controllerType = 'coffee' if pageFiles.coffee
        if pageFiles[controllerType]?.length
            if pageFiles[controllerType].length == 1
                page.controller = pageFiles[controllerType][0].path
            else
                controller = findObjectByFields pageFiles.jade, {name: "controller.#{controllerType}"}
                page.controller = controller.path


        files.pages.push page
        routes[page.name] = page.template if page.template

libs = []
buildFiles = ->
    getApplicationFiles()
    getPages()
    log files

    # Build all scripts
    fs.removeSync "#{publicRoot}/js"
    fs.mkdirpSync "#{publicRoot}/js"
    for file in files.js
        content = fs.readFileSync file.path
        path = file.path.replace(sourceRoot, "#{publicRoot}/js")
        fileName = path.split('/').pop()
        dirPath = path.replace fileName, ''
        fs.mkdirpSync dirPath
        fs.openSync path, 'w' # new file or clean exists
        fs.writeFileSync path, content

    for file in files.coffee
        content = fs.readFileSync file.path, charset
        path = file.path.replace(sourceRoot, "#{publicRoot}/js")
        path = path.replace /\.coffee$/, ".js"
        fileName = path.split('/').pop()
        dirPath = path.replace fileName, ''
        fs.mkdirpSync dirPath
        fs.openSync path, 'w' # new file or clean exists
        content = coffee.compile content , {bare:true}
        fs.writeFileSync path, content

    # Build all jades in one file (main.css)
    fs.removeSync "#{publicRoot}/css"
    fs.mkdirpSync "#{publicRoot}/css"
    mainPath = "#{publicRoot}/css/main.css"
    mainStylPath = "#{sourceRoot}/main.styl"
    mainContent = fs.readFileSync mainStylPath, charset
    for file in files.styl
        if file.path == mainStylPath then continue
        mainContent += "\n@import \"#{file.path}\""
    content = stylus(mainContent)
        .use(nib())
        .import('nib')
        .render()
    log content
    fs.writeFileSync mainPath, content


    # Build pages
    fs.removeSync "#{appRoot}/views"
    fs.mkdirpSync "#{appRoot}/views"
    for page in files.pages
        content = fs.readFileSync file.path, charset
        path = file.path.replace(sourceRoot, "#{appRoot}/views")
        fileName = path.split('/').pop()
        ext = getExtension fileName
        if ext == 'jade'
            path = path.replace /\.jade$/, ".html"
        path = path.replace /\.html$/, ".scala.html"
        dirPath = path.replace fileName, ''
        fs.mkdirpSync dirPath
#        fs.openSync path, 'w' # new file or clean exists
#        content = coffee.compile content , {bare:true}
#        fs.writeFileSync path, content
#
#        #content = compileTemplate page.template

compileTemplate = (path) ->

    content = null

    switch ext
        when 'html'
            content = fs.readFileSync path
        when 'jade'
            parser = jade.compile c
            locals = {scripts: scripts, libs: libs}
            result = parser(locals)








#run
do ->
    buildFiles()
    runServer()



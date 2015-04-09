#CONST
SEC = 1000
MIN = 60 * SEC
HOUR = MIN * 60
DAY = HOUR * 24
WEEK = DAY * 7
MONTH = DAY * 30
YEAR = 365 * DAY


# delete objetct and properties
emptyObject = (obj) ->
    for own key of obj
        delete obj[key]

makeArray = (object) -> # maybe delete?
    for k,v of object
        v

# get random integer value [min,max]
getRandomIntFast = (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min;

getRandomInt = (min, max, system = 10) ->
    min = parseInt(min, system)
    max = parseInt(max, system)
    float = Math.random() * (max - min + 1)
    int = Math.floor(float) + min;
    return if system == 10 then int else int.toString(system)

fixEvent = (e) ->
    # получить объект событие для IE
    e = e || window.event

    # добавить pageX/pageY для IE
    if e.pageX == null and e.clientX != null
        html = document.documentElement
        body = document.body
        e.pageX = e.clientX + (html and html.scrollLeft or body && body.scrollLeft or 0) - (html.clientLeft or 0)
        e.pageY = e.clientY + (html and html.scrollTop or body && body.scrollTop or 0) - (html.clientTop or 0)

    # добавить which для IE
    if !e.which && e.button
        e.which = e.button & 1 ? 1 : ( e.button & 2 ? 3 : ( e.button & 4 ? 2 : 0 ) )

    return e

$log = (args...) ->
    if window.DEV_MODE
        console.log.apply console, arguments

findObjectByFields = (array, data) ->
    found = null
    for item in array
        matched = false
        for k, v of data
            matched = item[k] == v
            if !matched then break

        if matched
            found = item
            break
            return found
    found

removeElementFromArray = (element, array) ->
    existingIndex = array.indexOf element
    if existingIndex >= 0
        return array.splice existingIndex, 1

removeAll = (from, elements) ->
    for element in elements
        removeElementFromArray(element, from)

pushAll = (target, toPush) ->
    for item in toPush
        if target.indexOf(item) == -1
            target.push item

updateObject = (target) ->
    for source in arguments
        if source == target then continue
        for key, value of source
            target[key] = source[key]
    target

getBigTimestamp = ->
    farInTheFuture = 13788003380350

# Отсечь секунды и миллисекунды, вернуть TS
toMinutes = (ts) ->
    obj = new Date ts
    new Date(obj.getFullYear(), obj.getMonth(), obj.getDate(), obj.getHours(), obj.getMinutes()).getTime()

# Отсечь и вернуть время в минутах
justMinutes = (ts) ->
    res = toMinutes ts
    res/(60*1000)

# If CMD or CTRL key for shortcuts
isCmd = (e) -> e.metaKey or e.ctrlKey

# Обрезаем урл по кол-ву символов
# 2 типа - 1.Обрезаем в конце + '...', 2.Обрезаем в середине + ' ... '
urlCropper = (url, count, type) ->
    url = $.trim(url)
    # Обрезаем http, https и т.п.
    url = url.replace(/(http\:\/\/)|(https\:\/\/)|(www\.)/gi, '')
    # Если последний символ слэш, его тоже удаляем
    if url[url.length-1] == '/'
        url = url.substr(0,url.length-1)

    if url.length > count
        switch type
            # Обрезаем ссылку по середине и вставляем ' ... '
            when 'middle'
                start = Math.floor(url.length / 2) - Math.floor(count / 2) - 2
                end = Math.floor(url.length / 2) + Math.floor(count / 2) - 2
                url = url.substr(0, start) + ' ... ' + url.substr(end, url.length)
            # Обрезаем текст в конце и добавляем '...'
            when 'end'
                url = url.substr(0,count-3) + '...'
    url

doGetCaretPosition = (oField) ->
    iCaretPos = 0

    if document.selection
        oField.focus()
        oSel = document.selection.createRange()

        oSel.moveStart 'character', -oField.value.length
        iCaretPos = oSel.text.length
    else if oField.selectionStart || oField.selectionStart == '0'
        iCaretPos = oField.selectionStart;

    iCaretPos

getUrlFormat = (url) ->
    re = /(http:\/\/)|(https:\/\/)/
    url = $.trim(url)
    if !re.test(url)
        url = 'http://'+url

    url

shuffle = (array) ->
    counter = array.length
    while counter > 0
        index = Math.floor(Math.random() * counter)
        counter--
        temp = array[counter]
        array[counter] = array[index]
        array[index] = temp

    return array


#Canvas animation wrapper
requestAnimFrame = requestAnimationFrame ||
    webkitRequestAnimationFrame          ||
    mozRequestAnimationFrame             ||
    ( callback ) ->
        setTimeout(callback, 1000 / 60);


selectElementContents = (el) ->
    range = document.createRange()
    range.selectNodeContents(el)
    sel = window.getSelection()
    sel.removeAllRanges()
    sel.addRange(range)

getOnlyTime = (ts) ->
    newDate = new Date(ts)
    newDate.setHours(0,0,0,0)
    newDateTS = newDate.getTime()
    ts - newDateTS


#Вставляем и центрируем картинку
imageIn = (img, sizeX, sizeY, whole, rel) ->
    kx = sizeX / img.width
    ky = sizeY / img.height
    #blog "in", img, sizeX
    if whole  ##Здесь картинка гарантированно влезет в прямоугольник (целая)
        scale = if kx<ky then kx else ky
    else      ##Здесь картинка гарантированно покроет прямоугольник (превью)
        scale = if kx>ky then kx else ky
    if !scale then scale = 1  #Если вдруг масштаб вычислить не удастся, просто двигаем без масштаба

    width = img.width * scale
    height = img.height * scale

    css =
        width: width
        height: height

        marginTop: -(height-sizeY)/2 + 'px'
        marginLeft: -(width-sizeX)/2 + 'px'

    if rel  # переводим в проценты
        css.width = 100*width/sizeX + '%'
        css.height = 100*height/sizeY + '%'

        css.marginTop = 100*parseInt(css.marginTop) / sizeX + '%'
        css.marginLeft = 100*parseInt(css.marginLeft) / sizeY + '%'

    $(img).css css
    return css


# Math
Math.easeInOutQuad = (t, b, c, d) ->
    #t - current time, b - start value, c - change in value, d - duration
    t /= d/2
    if t < 1 then return c/2*t*t + b
    t--
    return -c/2 * (t*(t-2) - 1) + b


#Array
makeArrayByLength = (l) ->
    a=new Array()
    a.length = l
    a

makeArrayByFromTo = (from, to) ->
    for c in [from...to+1]
        c

#color transforms #TDO color data-type (class)
getColor = (color) ->
    if !color then return false
    if color.indexOf('rgba')+1
        color = color.replace(/[()\sa-z]/g, '').split(",")
        color =
            r: +color[0]
            g: +color[1]
            b: +color[2]
            a: +color[3]

    color

makeRGBA = (color) ->
    'rgba('+color.r+', '+color.g+', '+color.b+', '+color.a+')'

makeHEX = (color) ->
    for i of color
        color[i] = color[i].toString(16)
    '#'+color.r+color.g+color.b

# --- email ---
isEmail = (mail) ->
    /[\w.]+\@[\w.]+\.\w{2,}/g.test(mail)

# --- strings ---
joinStrings = (strings, separator = ' ') ->
    #TODO если сепаратор не пробел, надо следить за пустыми строками и undefined
    res = strings.join(separator).replace(/\s+/g, ' ').replace(/(^\s+)|(\s+$)/g, '') # trim


#dev helper
DEV_MODE = false

switchDevMode = (state) ->
    DEV_MODE = !DEV_MODE
    if state then DEV_MODE = true

    if DEV_MODE
        localStorage['DEV_MODE'] = true
    else
        delete localStorage['DEV_MODE']

loadDevMode = ->
    DEV_MODE = localStorage['DEV_MODE'] || false

loadDevMode()

#---

# --- flow ---
class AsyncFlow # mb use acync.js or promises?
    constructor: () ->
        @actions = []
        @completed = 0
        @succeeded = 0

    add: (action) ->
        @actions.push action

    fire: (cb) ->
        for i in @actions
            do (i) => # next function
                i.action (res) =>
                    @completed++
                    if typeof res == 'undefined' then res = true
                    if res
                        @succeeded++
                        i.completed = true
                        if @completed == @actions.length
                            if @completed == @succeeded then cb? true else cb? false

#
keyboard =
    backspace: 8,
    tab:    9,
    enter:  13,
    shift:  16,
    ctrl:   17,
    alt:    18,
    caps:   20,
    esc:    29,
    space:  32,
    left:   37,
    up:     38,
    right:  39,
    down:   40


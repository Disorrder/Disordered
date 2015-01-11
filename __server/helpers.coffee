# --- filters ---
global.timestampMask = (ts, mask) ->
    shortMonthes = ["янв", "фев", "мар", "апр", "май", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"]
    days = ["понедельник", "вторник", "среда", "четверг", "пятница", "суббота", "воскресенье"]
    shortDays = ["пн", "вт", "ср", "чт", "пт", "сб", "вс"]

    DATE = new Date ts
    lib = {}
    #Date: 01.01.1970
    lib.D = DATE.getDate()
    lib.DD = if lib.D < 10 then "0"+lib.D else lib.D

    lib.M = DATE.getMonth()+1 # Январь - 0
    lib.MM = if lib.M < 10 then "0"+lib.M else lib.M

    lib.MMM  = shortMonthes[lib.M-1] # сокращённый месяц (Янв)
    #lib.MMMM = localization.translate(153+lib.M)[0] # полный месяц (Январь)
    #lib.ofMMMM = localization.translate(153+lib.M)[1] #родительный падеж (Января)

    lib.YYYY = DATE.getFullYear() # год
    lib.YY = (''+lib.YYYY).substr 2

    #Time: 11:11:11, Friday
    lib.h = DATE.getHours()
    lib.hh = if lib.h < 10 then "0"+lib.h else lib.h

    lib.m = DATE.getMinutes()
    lib.mm = if lib.m < 10 then "0"+lib.m else lib.m

    lib.s = DATE.getSeconds()
    lib.ss = if lib.s < 10 then "0"+lib.s else lib.s

    lib.d = DATE.getDay() # день недели
    lib.ddd  = shortDays[lib.d] # сокращённый день недели (пт)
    lib.dddd = days[lib.d] # полный день недели (Пятница)

    str = mask
    str = str.replace /(dddd|ddd|DD|D|MMM|MM|M|YYYY|YY|hh|h|mm|m|ss|s)/g, (mem) -> lib[mem]
    str
# -------


global.log = (args...) ->
    time = timestampMask Date.now(), "DD.MM.YYYY hh:mm:ss"
    args.unshift time
    console.log.apply console, args

# -- objects and arrays ---
global.findObjectByFields = (array, data) ->
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


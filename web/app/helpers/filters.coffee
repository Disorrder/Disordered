disordered.filter 'reverse', () ->
    (items) ->
        if !items?
            return []

        if typeof items == 'object'
            items.slice().reverse()
        else
            items.reverse()

disordered.filter 'toHTML', () ->
    (text) ->
        text?.replace(/\n/g, '<br>')

disordered.filter 'timestampMask', (localization) ->
    (items, search) ->
        if items? and !isNaN(items)
            DATE = new Date items
            lib = {}
            #Date: 01.01.1970
            lib.D = DATE.getDate()
            if lib.D < 10 then lib.DD = "0"+lib.D else lib.DD = lib.D

            lib.M = DATE.getMonth()+1 # хватит удалять эту единичку! Январь - 0
            if lib.M < 10 then lib.MM = "0"+lib.M else lib.MM = lib.M

            lib.MMM  = localization.translate(153+lib.M)[2] # сокращённый месяц (Янв)
            lib.MMMM = localization.translate(153+lib.M)[0] # полный месяц (Январь)
            lib.ofMMMM = localization.translate(153+lib.M)[1] #родительный падеж (Января)

            lib.YYYY = DATE.getFullYear() # год
            lib.YY = (''+lib.YYYY).substr 2

            #Time: 11:11:11, Friday
            lib.h = DATE.getHours()
            if lib.h < 10 then lib.hh = "0"+lib.h else lib.hh = lib.h

            lib.m = DATE.getMinutes()
            if lib.m < 10 then lib.mm = "0"+lib.m else lib.mm = lib.m

            lib.s = DATE.getHours()
            if lib.s < 10 then lib.ss = "0"+lib.s else lib.ss = lib.s

            lib.d = DATE.getDay() # день недели
            lib.ddd  = localization.translate(147+lib.d)[1] # сокращённый день недели (пт)
            lib.dddd = localization.translate(154+lib.d)[0] # полный день недели (Пятница)

            str = search or localization.translate "timestampMask"
            str = str.replace /(date|time)/g, (mem) -> localization.translate "timestampMask_"+mem
            str = str.replace /(DD|D|ofMMMM|MMMM|MMM|MM|YYYY|YY|hh|h|mm|m|ss|s|dddd|ddd|d)/g, (mem) -> lib[mem]
            str

# Форматируем числа, x xxx xxx xxx по умолчанию разделитель - пробел
# В фильтре можно указать любой разделитель передав параметр - anyNumber | formatNumber:', '
disordered.filter 'formatNumber', () ->
    (num, separator) ->
        if !separator
            separator = " "

        if num
            bNegative = (num < 0)
            sDecimalSeparator = "."
            sOutput = num.toString()

            nDotIndex = sOutput.lastIndexOf(sDecimalSeparator)
            if nDotIndex == -1
                nDotIndex = sOutput.length

            sNewOutput = sOutput.substring(nDotIndex)
            nCount = -1

            for [nDotIndex..0]
                nCount++
                if ((nCount % 3 == 0) and (_i != nDotIndex) and (!bNegative or (_i > 1)))
                    sNewOutput = separator + sNewOutput
                sNewOutput = sOutput.charAt(_i-1) + sNewOutput

            return sNewOutput
        num


disordered.filter 'startFrom', () ->
    (input, start) ->
        start = +start
        input.slice(start)
error = (code, text) ->
    err: true
    code: code
    text: text

class Sequence

    constructor: (params, @repeats = 0) ->

        @buffer = []
        @results = []
        @endCb = null
        @_log = []
        @_debug = 0
        @safe = true

        @sequenceName = 'Undefined sequence'

        if typeof params != 'object'
            @delay = params || 0

        else
            @sequenceName = params.name
            @delay = params.delay
            @repeats = params.repeats
            @_debug = params.debug || 0
            @safe = params.safe || false

        @repeatsLeft = @repeats

    log: () ->
        if @_debug > 2 then console.log.apply console, arguments

    addStep: (method) ->
        @buffer.push method

    addSteps: (array) ->
        for step in array
            @addStep step

    tryStep: (step, next) =>
        
        if step.check?
            check = step.check()
            step.checkResult = !!check

            if check != true
                next true, step
                return

        if step.iterator?

            iteratorSteps = []
            iteratorStepsCounter = 0

            step.iterator (data) ->
                iteratorStepsCounter++
                iteratorSteps.push
                    name: step.name + ' ' + iteratorStepsCounter
                    data: data
                    var: step.var
                    async: step.async
                    iteratorCnt: iteratorStepsCounter
                    action: step.action

            @buffer = iteratorSteps.concat @buffer

            @_log.push
                name: step.name
                date: step.data
                var: step.var
                async: step.async
                iteratorCnt: step.iteratorCnt
                message:
                    text: 'Iterator worked, ' + iteratorStepsCounter + ' steps added'

            next [], step
            return

        @log 'TRY: ', step.name
        step.timestampStart = Date.now()

        method = step.action

        if step.timeout?
            timeout = new Timeout
                time: step.timeout
                complete: next
                expire: =>
                    @_log.push
                        name: step.name
                        date: step.data
                        var: step.var
                        async: step.async
                        iteratorCnt: step.iteratorCnt
                        message: 
                            err: true
                            text: 'Timeout expired'

                    next
                        err: true 
                    , step

        doTry = ->
            if step.timeout?
                method timeout.done, () =>
                    timeout.abort()
                    @tryStep step, @makeNext step
                , step.data, step.iteratorCnt
            else
                method next, () =>
                    @tryStep step, @makeNext step
                , step.data, step.iteratorCnt

        if @safe != true
            doTry()
        else
            try
                doTry()
            catch e

                @log 'CRASH: ', step.name, e.toString()

                @_log.push
                    name: step.name
                    date: step.data
                    var: step.var
                    async: step.async
                    iteratorCnt: step.iteratorCnt
                    message:
                        err: true
                        text: 'CRASH: ' + e.toString()

                if step.timeout?
                    timeout.abort()

                next (if step.error? then step.error else error 0, e.toString()), step

    makeNext: (step) => 
        (result) =>
            @next result, step 

    next: (result = null, fromStep) =>

        if result?.err == true
            @log 'ERROR: ', fromStep?.name

            if @repeatsLeft > 0
                @stepName = '-> ' + fromStep.name

                @_log.push
                    name: fromStep.name
                    date: fromStep.data
                    var: fromStep.var
                    async: fromStep.async
                    iteratorCnt: fromStep.iteratorCnt
                    message:
                        text: 'Retry step'
                        details: result

                @repeatsLeft--
                
                @tryStep fromStep, @makeNext fromStep
                return
            else
                @_log.push
                    name: fromStep.name
                    date: fromStep.data
                    var: fromStep.var
                    async: fromStep.async
                    iteratorCnt: fromStep.iteratorCnt
                    checkResult: fromStep.checkResult
                    message:
                        err: true
                        text: 'Step error'
                        details: result

                @finish
                    error: result
                    details: result.details
                    err: true
                    success: false
                    log: @_log
                    failedOn: @stepName

                return

        # Write step result to log ===========
        if fromStep?
            @log 'COMPLETE: ', fromStep.name

            fromStep.timestampEnd = Date.now()

            @_log.push
                name: fromStep.name
                date: fromStep.data
                var: fromStep.var
                async: fromStep.async
                iteratorCnt: fromStep.iteratorCnt
                checkResult: fromStep.checkResult
                message:
                    time: fromStep.timestampEnd - fromStep.timestampStart
                    text: 'Completed'
                    details: result

            if fromStep.var? and fromStep.checkResult != false

                if fromStep.iteratorCnt? and fromStep.async != true 
                    @[fromStep.var][fromStep.iteratorCnt-1] = result
                else
                    @[fromStep.var] = result
            else
                @results.push result

        if @buffer.length > 0
            # Check async sequence
            asyncSteps = []
            while @buffer[0]?.async == true
                asyncSteps.push @buffer.shift()

            if asyncSteps.length > 0
                asyncResults = []

                failedFlag = false
                completedCnt = 0
                asyncNext = (asyncResult, step) =>
                    @_log.push
                        name: step.name
                        date: step.data
                        var: step.var
                        async: step.async
                        iteratorCnt: step.iteratorCnt
                        message:
                            err: asyncResult?.err == true 
                            text: 'Async result'
                            details: asyncResult

                    if failedFlag == false
                        if asyncResult?.err == true 
                            failedFlag = true
                            @finish
                                error: asyncResult
                                details: asyncResult.details
                                err: true
                                success: false
                                log: @_log
                                failedOn: @stepName
                        else
                            completedCnt++
                            if completedCnt >= asyncSteps.length
                                @next asyncResults, step

                for step,i in asyncSteps
                    do (step,i) =>
                        @tryStep step, (res) ->
                            asyncResults[i] = res
                            asyncNext res, step

            else

                # fire new step
                @step = @buffer.shift()
                @stepName = @step.name || 'Step'

                repeats = @step.retry or @repeats
                delay = @step.delay or @delay
                    
                @repeatsLeft = repeats

                if delay > 0
                    setTimeout () =>
                        @tryStep @step, @makeNext @step
                    , delay
                else
                    @tryStep @step, @makeNext @step
        else
            # end
            @finish
                success: true
                err: false
                log: @_log
                results: @results

    finish: (results) ->
        @endCb? results

    fire: (@endCb) =>
        @next()

    repeatLast: () ->
        if @step?
            @step(@next)
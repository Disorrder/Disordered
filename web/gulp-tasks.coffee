gulp        = require 'gulp'
log         = require('gulp-util').log
fs          = require 'fs-extra'

class Task
    enabled: true
    task: null # Gulp task

    refresh: ->
        dependencies = []
        dependencies.push d for d in @dependencies when !Lib.list[d] or Lib.list[d].enabled

        @task = gulp.task @name, dependencies, => @action?() if @enabled
        @

    constructor: (@name, @dependencies, @action) ->
        @refresh()

    include: (name) ->
        @dependencies.push name
        @refresh()

    includeTo: (name) ->
        Lib.get(name).include @name

    setEnabled: (cond = false) ->
        @enabled = !!cond
        Lib.refresh()
    disable: -> @setEnabled false
    enable:  -> @setEnabled true


class Lib
    @initGulp: (gulpPtr) -> gulp = gulpPtr
    @list: {}

    @add: (name, dependencies, action) =>
        if typeof dependencies == 'function'
            action = dependencies
            dependencies = []
        if !Array.isArray dependencies then dependencies = [dependencies]

        @list[name] =  new Task name, dependencies, action

    @get: (name) => @list[name]

    @refresh: =>
        for name, task of @list
            task.refresh()

    @run: (method) =>
        method = @get method
        method.action?()
        method

# --- exports ---
for k, v of Lib
    exports[k] = v

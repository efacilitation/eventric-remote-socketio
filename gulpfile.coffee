gulp   = require 'gulp'
gutil  = require 'gulp-util'
grep   = require 'gulp-grep-stream'
mocha  = require 'gulp-mocha'
watch  = require 'gulp-watch'

gulp.on 'err', (e) ->
gulp.on 'task_err', (e) ->
  if process.env.NODE_ENV isnt 'workstation'
    gutil.log e
    process.exit 1

gulp.task 'spec', ->
  gulp.src('src/*.coffee')
    .pipe(mocha())

gulp.task 'default', ->
  gulp.src("src/*.coffee",
    read: false
  ).pipe watch(
    emit: "all"
  , (files) ->
    files
      .pipe(grep("**/*.spec.*"))
      .pipe(mocha(reporter: "spec")
        .on "error", (err) ->
          console.log err.stack  unless /tests? failed/.test(err.stack)
          return
      )
    return
  )
  return
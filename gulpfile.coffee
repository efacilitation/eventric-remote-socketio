gulp  = require 'gulp'
gutil = require 'gulp-util'

gulp.on 'err', (error) ->
gulp.on 'task_err', (error) ->
  gutil.log error.err.stack
  if process.env.CI
    gutil.log error
    process.exit 1

gulp.task 'watch', ->
  gulp.watch [
    'src/*.coffee'
  ], [
    'specs'
  ]

require('./gulp/build')(gulp)
require('./gulp/specs')(gulp)
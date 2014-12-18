gulp = require 'gulp'

gulp.on 'err', (e) ->
gulp.on 'task_err', (e) ->
  if process.env.CI
    gutil.log e
    process.exit 1

gulp.on 'err', (e) ->
gulp.on 'task_err', (e) ->
  if process.env.CI
    gutil.log e
    process.exit 1

gulp.task 'watch', ->
  gulp.watch [
    'src/*.coffee'
  ], [
    'spec'
  ]

require('./gulp/build')(gulp)
require('./gulp/spec')(gulp)
require('./gulp/bump')(gulp)
coffee = require 'gulp-coffee'
del = require 'del'
runSequence = require 'run-sequence'

module.exports = (gulp) ->
  gulp.task 'build', (callback) ->
    runSequence 'build:clean', 'build:src', callback


  gulp.task 'build:clean', (callback) ->
    del './build', force: true, callback


  gulp.task 'build:src', ->
    gulp.src('src/endpoint.coffee')
      .pipe(coffee({bare: true}))
      .pipe(gulp.dest('build/src'))

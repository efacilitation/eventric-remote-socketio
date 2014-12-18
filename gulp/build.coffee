coffee      = require 'gulp-coffee'
del         = require 'del'
runSequence = require 'run-sequence'

module.exports = (gulp) ->
  gulp.task 'build', (next) ->
    runSequence 'build:clean', 'build:src', next

  gulp.task 'build:clean', (next) ->
    del './build', force: true, next

  gulp.task 'build:src', ->
    gulp.src(['index.coffee', '+(src)/!(*.spec)*.coffee'])
      .pipe(coffee({bare: true}))
      .pipe(gulp.dest('build/src'))

mocha = require 'gulp-mocha'

module.exports = (gulp) ->

  gulp.task 'spec', ->
    gulp.src('src/*.coffee')
      .pipe(mocha())
mocha = require 'gulp-mocha'

module.exports = (gulp) ->

  gulp.task 'specs', ->
    gulp.src('src/*.coffee')
      .pipe(mocha())
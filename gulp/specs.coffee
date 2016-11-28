mocha = require 'gulp-mocha'

module.exports = (gulp) ->

  gulp.task 'specs', ->
    gulp.src [
      'src/spec_setup.coffee'
      'src/**/*.coffee'
    ]
    .pipe mocha()

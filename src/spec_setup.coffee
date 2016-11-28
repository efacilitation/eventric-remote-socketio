require('es6-promise').polyfill()

root = if window? then window else global

root.sinon = require 'sinon'
root.chai = require 'chai'
root.expect = chai.expect
root.sandbox = sinon.sandbox.create()

sinonChai = require 'sinon-chai'
chai.use sinonChai

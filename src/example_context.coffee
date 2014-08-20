eventric = require 'eventric'

example = eventric.context 'Example'

class Something
  create: (callback) ->
    @$emitDomainEvent 'SomethingCreated', {}
    callback()

example.addAggregate 'Something', Something

example.defineDomainEvent 'SomethingCreated', ->

example.addCommandHandlers
  CreateSomething: (params, callback) ->
    @$repository('Something').create()
    .then (id) =>
      @$repository('Something').save id
    .then (id) ->
      callback null, id
    .catch (error) ->
      callback error

module.exports = example
eventric = require 'eventric'

example = eventric.context 'Example'

class Something
  create: (callback) ->
    @$emitDomainEvent 'SomethingCreated', {}
    callback()

  modify: ->
    @$emitDomainEvent 'SomethingModified', {}


example.addAggregate 'Something', Something

example.defineDomainEvent 'SomethingCreated', ->
example.defineDomainEvent 'SomethingModified', ->

example.addCommandHandlers
  CreateSomething: (params, callback) ->
    @$repository('Something').create()
    .then (id) =>
      @$repository('Something').save id
    .then (id) ->
      callback null, id
    .catch (error) ->
      callback error

  ModifySomething: (params, callback) ->
    @$repository('Something').findById params.id
    .then (something) =>
      something.modify()
      @$repository('Something').save params.id
    .then (id) ->
      callback null, id
    .catch (error) ->
      callback error

module.exports = example
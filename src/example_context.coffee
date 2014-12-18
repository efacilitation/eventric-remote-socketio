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
    @$aggregate.create 'Something'
    .then (aggregate) ->
      aggregate.$save()
    .then (aggregateId) ->
      callback null, aggregateId
    .catch (error) ->
      callback error

  ModifySomething: (params, callback) ->
    @$aggregate.load 'Something', params.id
    .then (something) ->
      something.modify()
      something.$save()
    .then (id) ->
      callback null, id
    .catch (error) ->
      callback error

module.exports = example
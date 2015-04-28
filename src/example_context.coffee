eventric = require 'eventric'

example = eventric.context 'Example'

class Something
  create: (params, callback) ->
    @$emitDomainEvent 'SomethingCreated', {}
    callback.resolve()

  modify: (params, callback) ->
    @$emitDomainEvent 'SomethingModified', {}
    callback.resolve()


example.addAggregate 'Something', Something

example.defineDomainEvent 'SomethingCreated', ->
example.defineDomainEvent 'SomethingModified', ->

example.addCommandHandlers
  CreateSomething: (params, callback) ->
    @$aggregate.create 'Something'
    .then (aggregate) ->
      aggregate.$save()
    .then (aggregateId) ->
      callback.resolve aggregateId
    .catch (error) ->
      callback.reject error

  ModifySomething: (params, callback) ->
    @$aggregate.load 'Something', params.id
    .then (aggregate) ->
      aggregate.modify null, callback
      aggregate.$save()
    .then (aggregateId) ->
      callback.resolve aggregateId
    .catch (error) ->
      callback.reject error

module.exports = example
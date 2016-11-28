eventric = require 'eventric'

example = eventric.context 'Example'

class Something
  create: ->
    @$emitDomainEvent 'SomethingCreated', {}

  modify: ->
    @$emitDomainEvent 'SomethingModified', {}


example.addAggregate 'Something', Something

example.defineDomainEvent 'SomethingCreated', ->
example.defineDomainEvent 'SomethingModified', ->

example.addCommandHandlers
  CreateSomething: ->
    @$aggregate.create 'Something'
    .then (aggregate) ->
      aggregate.$save()


  ModifySomething: (params) ->
    @$aggregate.load 'Something', params.id
    .then (aggregate) ->
      aggregate.modify()
      aggregate.$save()


module.exports = example

eventric = require 'eventric'

example = eventric.context 'Example'

class Something
  create: ->
    @$emitDomainEvent 'SomethingCreated'

  modify: ->
    @$emitDomainEvent 'SomethingModified'


example.addAggregate 'Something', Something

example.defineDomainEvent 'SomethingCreated', ->
example.defineDomainEvent 'SomethingModified', ->

example.addCommandHandlers
  CreateSomething: (params) ->
    @$aggregate.create 'Something'
    .then (something) ->
      something.$save()


  ModifySomething: (params) ->
    @$aggregate.load 'Something', params.id
    .then (something) ->
      something.modify()
      something.$save()


module.exports = example
require './compiler/scope'
require './compiler/symbol/_load'

symbols = Elang::Symbols.new
scope = Elang::Scope.new
symbols.add(Elang::Variable.new(scope, 'bawa'))
symbols.add(Elang::Variable.new(scope, 'biwi'))
symbols.add(Elang::Function.new(scope, nil, 'puts', [], 0))

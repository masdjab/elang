require './compiler/scope'
require './compiler/constant'
require './compiler/variable'
require './compiler/class_variable'
require './compiler/function'
require './compiler/class_function'
require './compiler/symbols'

symbols = Elang::Symbols.new
scope = Elang::Scope.new
symbols.add(Elang::Variable.new(scope, 'bawa'))
symbols.add(Elang::Variable.new(scope, 'biwi'))
symbols.add(Elang::Function.new(scope, nil, 'puts', [], 0))

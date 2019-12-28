require './compiler/symbols'
require './compiler/variable'
require './compiler/function'

symbols = Elang::Symbols.new
symbols.add(Elang::Variable.new('bawa'))
symbols.add(Elang::Variable.new('biwi'))
symbols.add(Elang::Function.new('puts'))

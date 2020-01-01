module Elang
  class SymbolRef
    attr_reader :symbol, :context, :location
    def initialize(symbol, context, location)
      @symbol = symbol
      @context = context
      @location = location
    end
  end
  
  
  class ConstantRef < SymbolRef
  end
  
  
  class VariableRef < SymbolRef
  end
  
  
  class FunctionRef < SymbolRef
  end
end

module Elang
  class SymbolRef
    attr_reader :symbol, :context, :location, :code_type
    
    def initialize(symbol, context, location, code_type)
      @symbol = symbol
      @context = context
      @location = location
      @code_type = code_type
    end
  end
  
  class ConstantRef < SymbolRef
  end
  
  class VariableRef < SymbolRef
  end
  
  class FunctionRef < SymbolRef
  end
  
  class FunctionIdRef < SymbolRef
  end
end

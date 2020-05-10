module Elang
  class SymbolRef
    attr_reader :symbol, :context, :location, :section_name
    
    def initialize(symbol, context, location, section_name)
      @symbol = symbol
      @context = context
      @location = location
      @section_name = section_name
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

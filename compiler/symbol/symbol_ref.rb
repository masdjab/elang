module Elang
  class SymbolRef
    attr_reader :symbol, :location
    
    def initialize(symbol, location)
      @symbol = symbol
      @location = location
    end
  end
  
  class GlobalVariableRef < SymbolRef
  end
  
  class LocalVariableRef < SymbolRef
  end
  
  class FunctionRef < SymbolRef
  end
end

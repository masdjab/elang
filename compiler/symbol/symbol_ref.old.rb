module Elang
  class CodeContext
    attr_accessor :name
    def initialize(name)
      @name = name
    end
    def to_s
      @name.to_s
    end
  end
  
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
  
  class FunctionIdRef < SymbolRef
  end
  
  class ShortCodeRef < SymbolRef
  end
  
  class NearCodeRef < SymbolRef
  end
  
  class FarCodeRef < SymbolRef
  end
  
  class AbsCodeRef < SymbolRef
  end
end

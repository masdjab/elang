module Elang
  class SymbolReference
    REF_FUNCTION = 1
    
    attr_accessor :context, :identifier, :ref_type, :location
    
    def initialize(context, identifier, ref_type, location)
      @context = context
      @identifier = identifier
      @ref_type = ref_type
      @location = location
    end
  end
end

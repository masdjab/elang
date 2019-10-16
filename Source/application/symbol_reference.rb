module Elang
  class SymbolReference
    attr_accessor :context, :identifier, :ref_type, :location, :origin
    
    def initialize(context, identifier, ref_type, location, origin = 0)
      @context = context
      @identifier = identifier
      @ref_type = ref_type
      @location = location
      @origin = origin
    end
  end
end

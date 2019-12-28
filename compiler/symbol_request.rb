module Assembly
  class SymbolRequest
    attr_accessor :identifier, :location, :type
    def initialize(identifier, location, type)
      @identifier = identifier
      @location = location
      @type = type
    end
  end
end

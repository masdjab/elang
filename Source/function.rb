module Elang
  class EFunction
    attr_accessor :name, :offset, :arguments
    
    def initialize(name, offset, arguments = [])
      @name = name
      @offset = offset
      @arguments = arguments
    end
  end
end

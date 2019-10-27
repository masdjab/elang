module Elang
  class EFunction
    attr_accessor :context, :name, :offset, :arguments
    
    def initialize(context, name, offset, arguments = [])
      @context = context
      @name = name
      @offset = offset
      @arguments = arguments
    end
  end
end

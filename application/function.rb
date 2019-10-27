module Elang
  class EFunction
    attr_accessor :context, :name, :arguments
    
    def initialize(context, name, arguments = [])
      @context = context
      @name = name
      @arguments = arguments
    end
  end
end

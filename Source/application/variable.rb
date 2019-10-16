module Elang
  class EVariable
    attr_reader :name, :context
    
    def initialize(name, context)
      @name = name
      @context = context
    end
  end
end

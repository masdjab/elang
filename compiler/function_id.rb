module Elang
  class FunctionId
    attr_reader :scope, :name
    
    def initialize(scope, name)
      @scope = scope
      @name = name
    end
  end
end

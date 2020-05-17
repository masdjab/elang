module Elang
  class FunctionId
    attr_reader :context, :scope, :name
    
    def initialize(context, scope, name)
      @context = context
      @scope = scope
      @name = name
    end
  end
end

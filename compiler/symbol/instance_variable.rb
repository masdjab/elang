module Elang
  class InstanceVariable
    attr_reader :context, :scope, :name, :index
    
    def initialize(context, scope, name, index)
      @index = index
      @context = context
      @scope = scope
      @name = name
    end
  end
end

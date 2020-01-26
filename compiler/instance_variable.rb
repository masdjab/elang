module Elang
  class InstanceVariable
    attr_reader :scope, :name, :index
    
    def initialize(scope, name, index)
      @index = index
      @scope = scope
      @name = name
    end
  end
end

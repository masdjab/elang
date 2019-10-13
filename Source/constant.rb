module Elang
  class EConstant
    attr_reader :scope, :name, :value
    
    def initialize(value, name = nil, scope = nil)
      @scope = scope
      @name = name
      @value = value
    end
  end
end

module Elang
  class Class
    attr_reader :scope, :name, :parent, :index
    
    def initialize(scope, name, parent, index)
      @index = index
      @scope = scope
      @name = name
      @parent = parent
    end
  end
end

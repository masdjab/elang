module Elang
  class Class
    CLS_ID_NULL   = 0
    CLS_ID_FALSE  = 2
    CLS_ID_TRUE   = 4
    CLS_ID_STRING = 6
    
    attr_reader :scope, :name, :parent, :index
    
    def initialize(scope, name, parent, index)
      @index = index
      @scope = scope
      @name = name
      @parent = parent
    end
  end
end

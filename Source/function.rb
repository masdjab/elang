module Elang
  class EFunction
    attr_reader   :function_id, :scope, :name
    attr_accessor :arguments, :variables, :code
    
    @@function_id = 0
    
    def initialize(name, scope = nil)
      @@function_id += 1
      @function_id = @@function_id
      @scope = nil
      @name = name
      @arguments = []
      @variables = []
      @code = ""
    end
  end
end

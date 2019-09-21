module Elang
  class EFunction
    attr_reader   :name
    attr_accessor :arguments, :variables, :code
    
    def initialize(name)
      @name = name
      @arguments = []
      @variables = []
      @code = ""
    end
  end
end

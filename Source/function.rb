module Elang
  class EFunction
    attr_reader   :name
    attr_accessor :arguments, :local_variables, :code
    
    def initialize(name)
      @name = name
      @arguments = []
      @local_variables = []
      @code = ""
    end
  end
end

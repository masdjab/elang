module Elang
  class EApplication
    attr_reader :name, :classes, :functions, :variables, :constants
    
    def initialize(name)
      @name = name
      @classes = []
      @functions = []
      @variables = []
      @constants = []
    end
  end
end

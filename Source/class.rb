module Elang
  class EClass
    attr_reader   :name, :functions, :ivars
    
    def initialize(name)
      @name = name
      @functions = []
      @ivars = []
    end
  end
end

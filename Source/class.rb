module Elang
  class EClass
    attr_reader   :name
    attr_accessor :functions
    
    def initialize(name)
      @name = name
      @functions = []
    end
  end
end

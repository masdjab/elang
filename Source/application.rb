module Elang
  class EApplication
    attr_accessor :name
    
    def initialize
      @name = ""
      @classes = []
      @i_vars = []
    end
  end
end

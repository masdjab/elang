module Elang
  class Variable
    RESERVED_VARIABLE_COUNT = 4
    
    @@index = 0
    
    attr_reader   :scope, :name
    attr_accessor :index
    
    def initialize(scope, name)
      @index = @@index = @@index + 1
      @scope = scope
      @name = name
    end
    def self.reset_index
      @@index = 0
    end
  end
end

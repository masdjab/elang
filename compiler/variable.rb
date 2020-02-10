module Elang
  class Variable
    RESERVED_VARIABLE_COUNT = 1
    
    @@index = 0
    
    attr_reader :scope, :name, :index
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

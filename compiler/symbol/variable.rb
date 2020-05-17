module Elang
  class Variable
    RESERVED_VARIABLE_COUNT = 8
    
    @@index = 0
    
    attr_reader   :context, :scope, :name
    attr_accessor :index
    
    def initialize(context, scope, name)
      @index = @@index = @@index + 1
      @context = context
      @scope = scope
      @name = name
    end
    def self.reset_index
      @@index = 0
    end
  end
end

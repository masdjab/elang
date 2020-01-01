module Elang
  class Variable
    @@index = 0
    
    attr_reader :scope, :name, :index
    def initialize(scope, name)
      @index = @@index = @@index + 1
      @scope = scope
      @name = name
    end
  end
end

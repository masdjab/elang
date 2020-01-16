module Elang
  class Class
    @@index = 0
    
    attr_reader :scope, :name, :parent, :index
    def initialize(scope, name, parent)
      @index = @@index = @@index + 1
      @scope = scope
      @name = name
      @parent = parent
    end
    def self.reset_index
      @@index = 0
    end
  end
end

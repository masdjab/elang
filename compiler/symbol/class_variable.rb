module Elang
  class ClassVariable
    @@index = 0
    
    attr_reader :context, :scope, :name, :index
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

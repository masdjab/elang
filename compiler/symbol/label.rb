module Elang
  class Label
    @@index = 0
    
    attr_reader   :index, :context, :scope, :name
    attr_accessor :offset
    
    def initialize(context, scope, name, offset)
      @index = @@index = @@index + 1
      @context = context
      @scope = scope
      @name = name
      @offset = offset
    end
  end
end

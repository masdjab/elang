module Elang
  class Label
    @@index = 0
    
    attr_reader :index, :scope, :name, :offset, :ref_context
    
    def initialize(scope, name, offset, ref_context)
      @index = @@index = @@index + 1
      @scope = scope
      @name = name
      @offset = offset
      @ref_context = ref_context
    end
  end
end

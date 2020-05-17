module Elang
  class SystemFunction
    attr_reader   :scope, :name
    attr_accessor :context, :offset
    
    def initialize(name, offset = 0)
      @context = nil
      @scope = nil
      @name = name
      @offset = offset
    end
  end
end

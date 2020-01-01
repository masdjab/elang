module Elang
  class Function
    @@index = 0
    
    attr_reader :scope, :name, :params, :offset, :index
    def initialize(scope, name, params, offset)
      @index = @@index = @@index + 1
      @scope = scope
      @name = name
      @params = params
      @offset = offset
    end
  end
end

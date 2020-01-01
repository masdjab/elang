module Elang
  class Function
    @@index = 0
    
    attr_reader :scope, :name, :params, :index
    def initialize(scope, name, params = [])
      @index = @@index = @@index + 1
      @scope = scope
      @name = name
      @params = params
    end
  end
end

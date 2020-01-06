module Elang
  class Function
    @@index = 0
    
    attr_accessor :offset
    attr_reader :scope, :name, :params, :index
    def initialize(scope, name, params, offset)
      @index = @@index = @@index + 1
      @scope = scope
      @name = name
      @params = params
      @offset = offset
    end
    def self.reset_index
      @@index = 0
    end
  end
end

module Elang
  class Function
    BASE_FUNCTION_ID = 1
    
    @@index = 0
    
    attr_accessor :offset
    attr_reader :scope, :receiver, :name, :params, :index
    def initialize(scope, receiver, name, params, offset)
      @index = @@index = @@index + 1
      @scope = scope
      @receiver = receiver
      @name = name
      @params = params
      @offset = offset
    end
    def self.reset_index
      @@index = 0
    end
  end
end

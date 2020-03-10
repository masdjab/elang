module Elang
  class Constant
    @@index = 0
    
    attr_reader :scope, :name, :value, :index
    def initialize(scope, name, value)
      @index = @@index = @@index + 1
      @scope = scope
      @name = name
      @value = value
    end
    def self.reset_index
      @@index = 0
    end
    def self.generate_name
      "const_#{@@index + 1}"
    end
  end
end

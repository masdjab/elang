module Elang
  class EConstant
    CONST_GENERAL = 1
    CONST_CLASS_NAME = 2
    
    attr_reader :scope, :name, :type, :value
    
    def initialize(value, options = {})
      @scope = options[:scope]
      @name = options[:name]
      @type = options.fetch(:type, nil)
      @value = value
    end
  end
end

module Elang
  module Assembler
    class Identifier
      METHOD = 1
      STRING_RES = 2
      VARIABLE = 3
      
      attr_accessor :scope, :name, :type, :value
      def initialize(scope, name, type, value)
        @scope = scope
        @name = name
        @type = type
        @value = value
      end
      def to_s
        if type == METHOD
          "MTH, #{@name}"
        elsif type == STRING_RES
          "SRS, #{@value.inspect}"
        elsif type == VARIABLE
          "VAR, #{@name}"
        else
          ""
        end
      end
    end
  end
end

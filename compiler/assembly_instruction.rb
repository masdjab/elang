module Elang
  module Assembly
    class Instruction
      attr_accessor :code, :desc
      
      def initialize(code = "", desc = "")
        @code = code
        @desc = desc
      end
      def to_s
        if !@code.empty?
          "  " + @code + (" " * (12 - @code.length)) + @desc
        elsif !@desc.empty?
          @desc
        else
          "  "
        end
      end
    end
  end
end

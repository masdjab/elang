module Elang
  module Assembly
    class CodeBuilder
      attr_reader :code, :instructions
      
      def initialize
        @code = ""
        @instructions = []
      end
      def <<(instruction)
        if !instruction.code.empty?
          @code = @code + Utils::Converter.hex2bin(instruction.code)
        end
        
        @instructions << instruction
      end
    end
  end
end

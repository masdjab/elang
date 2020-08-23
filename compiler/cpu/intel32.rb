require_relative '../converter'
require_relative '../symbol/symbol_ref'

module Elang
  module CpuModel
    class Intel32
      private
      def initialize
        @output = ""
      end
      def append_bin(code)
        @output += code
      end
      def append_hex(code)
        @output += Converter.hex2bin(code)
      end
      
      public
      def code_offset
        @output.length > 0 ? @output.length - 1 : nil
      end
      def code_length
        @output.length
      end
      def load_immediate(value)
        append_hex "B8" + Converter.int2hex(value, :dword, :be)
      end
      def push
        append_hex "50"
      end
      def pop
        append_hex "58"
      end
      def ret(count = 0)
        append_hex count > 0 ? "C2#{Converter.int2hex(4 * count, :word, :be)}" : "C3"
      end
      def set_global_variable(symbol)
        append_hex "A300000000"
        GlobalVariableRef.new symbol, self.code_offset - 3
      end
      def get_global_variable(symbol)
        append_hex "A100000000"
        GlobalVariableRef.new symbol, self.code_offset - 3
      end
      def set_local_variable(symbol)
        append_hex "894500"
        LocalVariableRef.new symbol, self.code_offset
      end
      def get_local_variable(symbol)
        append_hex "8B4500"
        LocalVariableRef.new symbol, self.code_offset
      end
      def call_function(symbol)
        append_hex "E800000000"
        FunctionRef.new symbol, self.code_offset - 3
      end
      def get_parameter(index)
        append_hex "8B45" + Converter.int2hex((index + 2) * 4, :byte, :be)
      end
      def set_jump_source(condition = nil)
        if condition.nil?
          append_hex "E900000000"
          self.code_offset - 3
        elsif condition == :nz
          append_hex "0F8500000000"
          self.code_offset - 3
        elsif condition == :zr
          append_hex "0F8400000000"
          self.code_offset - 3
        else
          nil
        end
      end
      def set_jump_target(source, target)
        @output[source, 4] = Converter.int2bin(target - (source + 4), :dword)
      end
      def output
        @output
      end
    end
  end
end

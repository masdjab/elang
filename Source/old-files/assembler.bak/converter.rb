module Elang
  module Assembler
    class Converter
      def self.bytes_to_str(*bytes)
        bytes.map{|x|x.chr}.join
      end
      def self.int_to_word(value)
        hi = (value & 0xff00) >> 8
        lo = value & 0xff
        lo.chr + hi.chr
      end
      def self.word_to_int(value)
        bytes = value.bytes
        (1 << 8) * bytes[1] + bytes[0]
      end
      def self.dword_to_int(value)
        bytes = value.bytes
        (1 << 24) * bytes[3] + (1 << 16) * bytes[2] + (1 << 8) * bytes[1] + bytes[0]
      end
    end
  end
end

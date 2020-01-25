module Elang
  module Utils
    class Converter
      def self.bytes_to_str(*bytes)
        bytes.map{|x|x.chr}.join
      end
      def self.int_to_byte(value)
        (value & 0xff).chr
      end
      def self.int_to_word(value)
        hi = (value & 0xff00) >> 8
        lo = value & 0xff
        lo.chr + hi.chr
      end
      def self.int_to_dword(value)
        word1 = value & 0xffff
        word2 = (value & 0xffff0000) >> 16
        self.int_to_word(word1) + self.int_to_word(word2)
      end
      def self.byte_to_int(value)
        value.bytes[0]
      end
      def self.word_to_int(value)
        bytes = value.bytes
        (1 << 8) * bytes[1] + bytes[0]
      end
      def self.dword_to_int(value)
        bytes = value.bytes
        (1 << 24) * bytes[3] + (1 << 16) * bytes[2] + (1 << 8) * bytes[1] + bytes[0]
      end
      def self.int_to_bhex(value)
        t = "0#{value.to_s(16)}"[-2..-1]
        "0" * (2 - t.length) + t
      end
      def self.int_to_whex(value)
        t = "000#{value.to_s(16)}"[-4..-1]
        "0" * (4 - t.length) + t
      end
      def self.int_to_bhex_be(value)
        self.int_to_byte(value).bytes.map{|x|self.int_to_bhex(x.ord)}.join
      end
      def self.int_to_whex_be(value)
        self.int_to_word(value).bytes.map{|x|self.int_to_bhex(x.ord)}.join
      end
      def self.hex_to_bin(hexstr)
        (0...(hexstr.length / 2)).map{|i|hexstr[2 * i, 2].hex.chr}.join
      end
      def self.bin_to_hex(binstr)
        binstr.bytes.map{|x|self.int_to_bhex(x.ord)}.join
      end
    end
  end
end

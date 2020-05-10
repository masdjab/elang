module Elang
  class Converter
    def self.lower_byte(value)
      value & 0xff
    end
    def self.upper_byte(value)
      (value & 0xff00) >> 8
    end
    def self.lower_word(value)
      lo = value & 0xffff
    end
    def self.upper_word(value)
      (value & 0xffff0000) >> 16
    end
    def self.lower_dword(value)
      value & 0xffffffff
    end
    def self.upper_dword(value)
      (value & 0xffffffff00000000) >> 32
    end
    def self.bytes_to_str(*bytes)
      bytes.map{|x|x.chr}.join
    end
    def self.int2bin(value, size)
      if size == :byte
        (value & 0xff).chr
      elsif size == :word
        self.int2bin(self.lower_byte(value), :byte) + self.int2bin(self.upper_byte(value), :byte)
      elsif size == :dword
        self.int2bin(self.lower_word(value), :word) + self.int2bin(self.upper_word(value), :word)
      elsif size == :qword
        self.int2bin(self.lower_dword(value), :dword) + self.int2bin(self.upper_dword(value), :dword)
      else
        raise "Invalid byte size code: #{size.inspect}."
      end
    end
    def self.bin2int(value)
      result = 0
      factor = [1, 0x100, 0x10000, 0x1000000, 0x100000000]
      rbytes = value.bytes
      (0...rbytes.count).each{|i|result += rbytes[i] * factor[i]}
      result
    end
    def self.int2hex(value, size, mode = :le)
      if bl = {:byte => 1, :word => 2, :dword => 4, :qword => 8}[size]
        vx = value
        hh = []
        
        (0...bl).each do |bx|
          hh << (vx & 0xff).to_s(16).rjust(2, "0")
          vx = vx >> 8
        end
        
        hh = hh.reverse if mode == :le
        hh.join
      else
        raise "Invalid byte size code: #{size.inspect}."
      end
    end
    def self.hex2bin(value)
      (0...(value.length / 2)).map{|i|value[2 * i, 2].hex.chr}.join
    end
    def self.bin2hex(value)
      value.bytes.map{|x|self.int2hex(x.ord, :byte)}.join
    end
  end
end

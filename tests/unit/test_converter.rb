require 'test-unit'
require './compiler/converter'

class TestConverter < Test::Unit::TestCase
  def test_bytes_to_str
    assert_equal 'abc123', Elang::Converter.bytes_to_str(0x61, 0x62, 0x63, 0x31, 0x32, 0x33)
    assert_equal '"ABC"', Elang::Converter.bytes_to_str(0x22, 0x41, 0x42, 0x43, 0x22)
  end
  def test_int2bin
    assert_equal 0.chr, Elang::Converter.int2bin(0, :byte)
    assert_equal 0x41.chr, Elang::Converter.int2bin(0x41, :byte)
    assert_equal 0xff.chr, Elang::Converter.int2bin(0xff, :byte)
    assert_equal 0.chr, Elang::Converter.int2bin(0x100, :byte)
    
    assert_equal 0.chr + 0.chr, Elang::Converter.int2bin(0, :word)
    assert_equal '56', Elang::Converter.int2bin(0x3635, :word)
    assert_equal 255.chr + 255.chr, Elang::Converter.int2bin(-1, :word)
    assert_equal 254.chr + 255.chr, Elang::Converter.int2bin(-2, :word)
    
    assert_equal 0.chr * 4, Elang::Converter.int2bin(0, :dword)
    assert_equal '5678', Elang::Converter.int2bin(0x38373635, :dword)
    assert_equal 255.chr * 4, Elang::Converter.int2bin(-1, :dword)
    assert_equal 254.chr + (255.chr * 3), Elang::Converter.int2bin(-2, :dword)
  end
  def test_bin2int
    assert_equal 0, Elang::Converter.bin2int(0.chr * 1)
    assert_equal 0, Elang::Converter.bin2int(0.chr * 2)
    assert_equal 0, Elang::Converter.bin2int(0.chr * 3)
    assert_equal 0, Elang::Converter.bin2int(0.chr * 4)
    
    assert_equal 0x12, Elang::Converter.bin2int(0x12.chr)
    assert_equal 0x1234, Elang::Converter.bin2int([0x34.chr, 0x12.chr].join)
    assert_equal 0x123456, Elang::Converter.bin2int([0x56.chr, 0x34.chr, 0x12.chr].join)
    
    assert_equal 0x3635, Elang::Converter.bin2int('56')
    assert_equal 65535, Elang::Converter.bin2int(255.chr + 255.chr)
    
    assert_equal 0x38373635, Elang::Converter.bin2int('5678')
    assert_equal 4294967295, Elang::Converter.bin2int(255.chr * 4)
  end
  def test_int2hex
    assert_equal '00', Elang::Converter.int2hex(0, :byte, :le)
    assert_equal '27', Elang::Converter.int2hex(0x27, :byte, :le)
    assert_equal 'ff', Elang::Converter.int2hex(0xff, :byte, :le)
    assert_equal '00', Elang::Converter.int2hex(0x100, :byte, :le)
    
    assert_equal "00", Elang::Converter.int2hex(0, :byte, :be)
    assert_equal "00", Elang::Converter.int2hex(0x100, :byte, :be)
    assert_equal "01", Elang::Converter.int2hex(1, :byte, :be)
    assert_equal "10", Elang::Converter.int2hex(16, :byte, :be)
    assert_equal "ff", Elang::Converter.int2hex(255, :byte, :be)
    assert_equal "ff", Elang::Converter.int2hex(0x1ff, :byte, :be)
    
    assert_equal '0000', Elang::Converter.int2hex(0, :word, :le)
    assert_equal '5678', Elang::Converter.int2hex(0x5678, :word, :le)
    assert_equal 'ffff', Elang::Converter.int2hex(65535, :word, :le)
    assert_equal '0000', Elang::Converter.int2hex(0x10000, :word, :le)
    
    assert_equal "0000", Elang::Converter.int2hex(0, :word, :be)
    assert_equal "0000", Elang::Converter.int2hex(0x10000, :word, :be)
    assert_equal "0100", Elang::Converter.int2hex(1, :word, :be)
    assert_equal "0080", Elang::Converter.int2hex(0x8000, :word, :be)
    assert_equal "3412", Elang::Converter.int2hex(0x1234, :word, :be)
    assert_equal "feff", Elang::Converter.int2hex(0xfffe, :word, :be)
    assert_equal "feff", Elang::Converter.int2hex(0x1fffe, :word, :be)
    
    assert_equal '00000000', Elang::Converter.int2hex(0, :dword, :le)
    assert_equal '00005678', Elang::Converter.int2hex(0x5678, :dword, :le)
    assert_equal '0000ffff', Elang::Converter.int2hex(65535, :dword, :le)
    assert_equal '00010000', Elang::Converter.int2hex(0x10000, :dword, :le)
    
    assert_equal "00000000", Elang::Converter.int2hex(0, :dword, :be)
    assert_equal "00000100", Elang::Converter.int2hex(0x10000, :dword, :be)
    assert_equal "01000000", Elang::Converter.int2hex(1, :dword, :be)
    assert_equal "00800000", Elang::Converter.int2hex(0x8000, :dword, :be)
    assert_equal "34120000", Elang::Converter.int2hex(0x1234, :dword, :be)
    assert_equal "feffffff", Elang::Converter.int2hex(0xfffffffe, :dword, :be)
    assert_equal "feffff1f", Elang::Converter.int2hex(0x1ffffffe, :dword, :be)
  end
  def test_hex2bin
    assert_equal "", Elang::Converter.hex2bin("")
    assert_equal 0.chr * 4, Elang::Converter.hex2bin("00000000")
    assert_equal 0.chr + "abcd" + 0.chr, Elang::Converter.hex2bin("006162636400")
    assert_equal "1234", Elang::Converter.hex2bin("31323334")
  end
  def test_bin2hex
    assert_equal "", Elang::Converter.bin2hex("")
    assert_equal "0041424300", Elang::Converter.bin2hex(0.chr + "ABC" + 0.chr)
    assert_equal "6173696170", Elang::Converter.bin2hex("asiap")
  end
end

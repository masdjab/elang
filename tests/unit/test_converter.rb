require 'test-unit'
require './utils/converter'

class TestConverter < Test::Unit::TestCase
  def test_bytes_to_str
    assert_equal 'abc123', Elang::Utils::Converter.bytes_to_str(0x61, 0x62, 0x63, 0x31, 0x32, 0x33)
    assert_equal '"ABC"', Elang::Utils::Converter.bytes_to_str(0x22, 0x41, 0x42, 0x43, 0x22)
  end
  def test_int_to_byte
    assert_equal 0.chr, Elang::Utils::Converter.int_to_byte(0)
    assert_equal 0x41.chr, Elang::Utils::Converter.int_to_byte(0x41)
    assert_equal 0xff.chr, Elang::Utils::Converter.int_to_byte(0xff)
    assert_equal 0.chr, Elang::Utils::Converter.int_to_byte(0x100)
  end
  def test_int_to_word
    assert_equal 0.chr + 0.chr, Elang::Utils::Converter.int_to_word(0)
    assert_equal '56', Elang::Utils::Converter.int_to_word(0x3635)
    assert_equal 255.chr + 255.chr, Elang::Utils::Converter.int_to_word(-1)
    assert_equal 254.chr + 255.chr, Elang::Utils::Converter.int_to_word(-2)
  end
  def test_int_to_dword
    assert_equal 0.chr * 4, Elang::Utils::Converter.int_to_dword(0)
    assert_equal '5678', Elang::Utils::Converter.int_to_dword(0x38373635)
    assert_equal 255.chr * 4, Elang::Utils::Converter.int_to_dword(-1)
    assert_equal 254.chr + (255.chr * 3), Elang::Utils::Converter.int_to_dword(-2)
  end
  def test_word_to_int
    assert_equal 0, Elang::Utils::Converter.word_to_int(0.chr + 0.chr)
    assert_equal 0x3635, Elang::Utils::Converter.word_to_int('56')
    assert_equal 65535, Elang::Utils::Converter.word_to_int(255.chr + 255.chr)
  end
  def test_dword_to_int
    assert_equal 0, Elang::Utils::Converter.dword_to_int(0.chr * 4)
    assert_equal 0x38373635, Elang::Utils::Converter.dword_to_int('5678')
    assert_equal 4294967295, Elang::Utils::Converter.dword_to_int(255.chr * 4)
  end
  def test_int_to_bhex
    assert_equal '00', Elang::Utils::Converter.int_to_bhex(0)
    assert_equal '27', Elang::Utils::Converter.int_to_bhex(0x27)
    assert_equal 'ff', Elang::Utils::Converter.int_to_bhex(0xff)
    assert_equal '00', Elang::Utils::Converter.int_to_bhex(0x100)
  end
  def test_int_to_whex
    assert_equal '0000', Elang::Utils::Converter.int_to_whex(0)
    assert_equal '5678', Elang::Utils::Converter.int_to_whex(0x5678)
    assert_equal 'ffff', Elang::Utils::Converter.int_to_whex(65535)
    assert_equal '0000', Elang::Utils::Converter.int_to_whex(0x10000)
  end
  def test_int_to_bhex_be
    assert_equal "00", Elang::Utils::Converter.int_to_bhex_be(0)
    assert_equal "00", Elang::Utils::Converter.int_to_bhex_be(0x100)
    assert_equal "01", Elang::Utils::Converter.int_to_bhex_be(1)
    assert_equal "10", Elang::Utils::Converter.int_to_bhex_be(16)
    assert_equal "ff", Elang::Utils::Converter.int_to_bhex_be(255)
    assert_equal "ff", Elang::Utils::Converter.int_to_bhex_be(0x1ff)
  end
  def test_int_to_whex_be
    assert_equal "0000", Elang::Utils::Converter.int_to_whex_be(0)
    assert_equal "0000", Elang::Utils::Converter.int_to_whex_be(0x10000)
    assert_equal "0100", Elang::Utils::Converter.int_to_whex_be(1)
    assert_equal "0080", Elang::Utils::Converter.int_to_whex_be(0x8000)
    assert_equal "3412", Elang::Utils::Converter.int_to_whex_be(0x1234)
    assert_equal "feff", Elang::Utils::Converter.int_to_whex_be(0xfffe)
    assert_equal "feff", Elang::Utils::Converter.int_to_whex_be(0x1fffe)
  end
  def test_hex_to_bin
    assert_equal "", Elang::Utils::Converter.hex_to_bin("")
    assert_equal 0.chr * 4, Elang::Utils::Converter.hex_to_bin("00000000")
    assert_equal 0.chr + "abcd" + 0.chr, Elang::Utils::Converter.hex_to_bin("006162636400")
    assert_equal "1234", Elang::Utils::Converter.hex_to_bin("31323334")
  end
  def test_bin_to_hex
    assert_equal "", Elang::Utils::Converter.bin_to_hex("")
    assert_equal "0041424300", Elang::Utils::Converter.bin_to_hex(0.chr + "ABC" + 0.chr)
    assert_equal "6173696170", Elang::Utils::Converter.bin_to_hex("asiap")
  end
end

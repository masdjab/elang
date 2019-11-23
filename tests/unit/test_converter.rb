require 'test-unit'
require './utils/converter'

class TestConverter < Test::Unit::TestCase
  def test_bytes_to_str
    assert_equal 'abc123', Elang::Utils::Converter.bytes_to_str(0x61, 0x62, 0x63, 0x31, 0x32, 0x33)
    assert_equal '"ABC"', Elang::Utils::Converter.bytes_to_str(0x22, 0x41, 0x42, 0x43, 0x22)
  end
  def test_int_to_word
    assert_equal 0.chr + 0.chr, Elang::Utils::Converter.int_to_word(0)
    assert_equal '56', Elang::Utils::Converter.int_to_word(0x3635)
    assert_equal 255.chr + 255.chr, Elang::Utils::Converter.int_to_word(-1)
    assert_equal 254.chr + 255.chr, Elang::Utils::Converter.int_to_word(-2)
  end
  def test_word_to_int
    assert_equal 0, Elang::Utils::Converter.word_to_int(0.chr + 0.chr)
    assert_equal 0x3635, Elang::Utils::Converter.word_to_int('56')
    assert_equal 65535, Elang::Utils::Converter.word_to_int(255.chr + 255.chr)
  end
  def test_int_to_dword
    assert_equal 0.chr * 4, Elang::Utils::Converter.int_to_dword(0)
    assert_equal '5678', Elang::Utils::Converter.int_to_dword(0x38373635)
    assert_equal 255.chr * 4, Elang::Utils::Converter.int_to_dword(-1)
    assert_equal 254.chr + (255.chr * 3), Elang::Utils::Converter.int_to_dword(-2)
  end
  def test_dword_to_int
    assert_equal 0, Elang::Utils::Converter.dword_to_int(0.chr * 4)
    assert_equal 0x38373635, Elang::Utils::Converter.dword_to_int('5678')
    assert_equal 4294967295, Elang::Utils::Converter.dword_to_int(255.chr * 4)
  end
  def test_int_to_bhex
    assert_equal '00', Elang::Utils::Converter.int_to_bhex(0)
    assert_equal '27', Elang::Utils::Converter.int_to_bhex(0x27)
    assert_equal 'FF', Elang::Utils::Converter.int_to_bhex(0xff)
    assert_equal '00', Elang::Utils::Converter.int_to_bhex(0x100)
  end
  def test_int_to_whex
    assert_equal '0000', Elang::Utils::Converter.int_to_whex(0)
    assert_equal '5678', Elang::Utils::Converter.int_to_whex(0x5678)
    assert_equal 'FFFF', Elang::Utils::Converter.int_to_whex(65535)
    assert_equal '0000', Elang::Utils::Converter.int_to_whex(0x10000)
  end
end

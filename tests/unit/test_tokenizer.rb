require 'test-unit'
require './compiler/tokenizer'

class TestTokenizer < Test::Unit::TestCase
  def test_multi_line
    cx = "text = 'Hello \\'world\\'...'\r\nputs text\r\na = 0x31 + 0.2815\r\n"
    puts (0...cx.length).map{|x|x % 10}.join
    puts cx.gsub("\r", '*').gsub("\n", '*')
    puts
    
    tokenizer = Elang::Tokenizer.new
    tokens = tokenizer.parse(cx)
    expected = "text| |=| |'Hello \\'world\\'...'|\r|\n|puts| |text|\r|\n|a| |=| |0|x|31| |+| |0|.|2815|\r|\n"
    actual = tokens.map{|x|x.text}.join("|")
    assert_equal expected, actual
  end
  def test_interpolation
    cx = "puts \"Name: \#{x.first} \#{x.last}\"\r\n"
    puts (0...cx.length).map{|x|x % 10}.join
    puts cx.gsub("\r", '*').gsub("\n", '*')
    puts
    
    tokenizer = Elang::Tokenizer.new
    tokens = tokenizer.parse(cx)
    expected = "puts| |\"Name: \#{x.first} \#{x.last}\"|\r|\n"
    actual = tokens.map{|x|x.text}.join("|")
    assert_equal expected, actual
  end
end

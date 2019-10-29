require 'test-unit'
require './compiler/tokenizer'

class TestTokenizer < Test::Unit::TestCase
  def test_parse_1
    cx = "text = 'Hello \\'world\\'...'\r\nputs text\r\na = b + c\r\n"
    puts (0...cx.length).map{|x|x % 10}.join
    puts cx.gsub("\r", '*').gsub("\n", '*')
    puts
    
    tokenizer = Elang::Tokenizer.new
    tokens = tokenizer.parse(cx)
    expected = "text| |=| |'Hello \\'world\\'...'|\r|\n|puts| |text|\r|\n|a| |=| |b| |+| |c|\r|\n"
    actual = tokens.map{|x|x.text}.join("|")
    assert_equal expected, actual
  end
end

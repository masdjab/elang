require 'test-unit'
require './compiler/tokenizer'

class TestTokenizer < Test::Unit::TestCase
  def show_code(code)
    puts (0...code.length).map{|x|x % 10}.join
    puts code.gsub("\r", '*').gsub("\n", '*').gsub("\t", '*')
    puts
  end
  def tokenize(code)
    show_code code
    Elang::Tokenizer.new.parse code
  end
  def join_text(tokens)
    tokens.map{|x|x.text}.join("|")
  end
  def test_simple_expression
    assert_equal "-3", join_text(tokenize("-3"))
  end
  def test_comment
    cx = "  # test comment\r\n  a = 2"
    assert_equal "a|=|2", join_text(tokenize(cx))
  end
  def test_multi_line
    cx = "  \ttext = 'Hello \\'world\\'...'\r\nputs text\r\na = 0x31 + 0.2815\r\n"
    expected = "text|=|'Hello \\'world\\'...'|\r\n|puts|text|\r\n|a|=|0x31|+|0.2815|\r\n"
    assert_equal expected, join_text(tokenize(cx))
  end
  def test_interpolation
    cx = "puts \"Name: \#{x.first} \#{x.last}\"\r\n"
    expected = "puts|\"Name: \#{x.first} \#{x.last}\"|\r\n"
    assert_equal expected, join_text(tokenize(cx))
  end
end

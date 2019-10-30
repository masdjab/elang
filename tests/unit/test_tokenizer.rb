require 'test-unit'
require './compiler/tokenizer'

class TestTokenizer < Test::Unit::TestCase
  def show_code(code)
    puts (0...code.length).map{|x|x % 10}.join
    puts code.gsub("\r", '*').gsub("\n", '*').gsub("\t", '*')
    puts
  end
  def tokenize(code)
    Elang::Tokenizer.new.parse code
  end
  def join_text(tokens)
    tokens.map{|x|x.text}.join("|")
  end
  def test_comment
    show_code cx = "  # test comment\r\n  a = 2"
    tokens = tokenize(cx)
    assert_equal "  |# test comment\r\n|  |a| |=| |2", join_text(tokens)
  end
  def test_multi_line
    show_code cx = "  \ttext = 'Hello \\'world\\'...'\r\nputs text\r\na = 0x31 + 0.2815\r\n"
    tokens = tokenize(cx)
    expected = "  \t|text| |=| |'Hello \\'world\\'...'|\r|\n|puts| |text|\r|\n|a| |=| |0|x|31| |+| |0|.|2815|\r|\n"
    assert_equal expected, join_text(tokens)
  end
  def test_interpolation
    show_code cx = "puts \"Name: \#{x.first} \#{x.last}\"\r\n"
    tokens = tokenize(cx)
    expected = "puts| |\"Name: \#{x.first} \#{x.last}\"|\r|\n"
    assert_equal expected, join_text(tokens)
  end
end

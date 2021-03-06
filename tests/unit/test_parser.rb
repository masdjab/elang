require 'test-unit'
require 'mocha/test_unit'
require './compiler/exception'
require './compiler/source_code'
require './compiler/parser'

class TestParser < Test::Unit::TestCase
  def _parse(code)
    Elang::Parser.new.parse(Elang::StringSourceCode.new(code))
  end
  def assert_single_number(code)
    tokens = _parse(code)
    assert_equal 1, tokens.count
    assert_equal 1, tokens[0].col
    assert_equal :number, tokens[0].type
  end
  def test_parse_return_type
    tokens = _parse("x = 2")
    assert_equal true, tokens.is_a?(Array)
    assert_equal true, tokens[0].is_a?(Elang::Token)
    assert_equal 5, tokens.count
    assert_equal [1, 2, 3, 4, 5], tokens.map{|x|x.col}
  end
  def test_parse_whitespace
    tokens = _parse("  \t  \t  ")
    assert_equal 1, tokens.count
    assert_equal :whitespace, tokens.first.type
  end
  def test_parse_linefeed
    tokens = _parse("x\r")
    assert_equal 2, tokens.count
    assert_equal :cr, tokens[1].type
    
    tokens = _parse("x\n")
    assert_equal 2, tokens.count
    assert_equal :lf, tokens[1].type
    
    tokens = _parse("x\r\n")
    assert_equal 2, tokens.count
    assert_equal :crlf, tokens[1].type
    
    tokens = _parse("x\r\r\n")
    assert_equal 3, tokens.count
    assert_equal :cr, tokens[1].type
    assert_equal :crlf, tokens[2].type
    
    tokens = _parse("\r\n\r\n")
    assert_equal 2, tokens.count
    assert_equal :crlf, tokens[0].type
    assert_equal :crlf, tokens[1].type
    
    tokens = _parse("\r\n\n")
    assert_equal 2, tokens.count
    assert_equal :crlf, tokens[0].type
    assert_equal :lf, tokens[1].type
  end
  def test_parse_comment
    tokens = _parse("aku#sudah tahu")
    assert_equal 2, tokens.count
    assert_equal :comment, tokens[1].type
    
    tokens = _parse("   \t   #  sudah lah # # #")
    assert_equal 2, tokens.count
    assert_equal :comment, tokens[1].type
  end
  def test_parse_number
    assert_single_number "000"
    assert_single_number "001"
    assert_single_number "1234567890"
    assert_single_number "000.215"
    assert_single_number "000.0"
    assert_single_number "000.000"
    assert_single_number "000.128"
    assert_single_number "000.123456789"
    assert_single_number "0.123456789"
    assert_single_number "22.123456789"
    assert_single_number "123456789.456"
    assert_single_number "0x213254"
    assert_single_number "0xabcdef"
    assert_single_number "0x12ac"
    
    tokens = _parse("12345.to_s")
    assert_equal 3, tokens.count
    assert_equal [:number, :dot, :identifier], tokens.map{|x|x.type}
    assert_equal [1, 6, 7], tokens.map{|x|x.col}
    assert_equal ["12345", ".", "to_s"], tokens.map{|x|x.text}
    
    assert_raise(Elang::ParsingError){_parse("0x2e.4")}
    assert_raise(Elang::ParsingError){_parse("0.")}
    assert_raise(Elang::ParsingError){_parse("123.")}
    assert_raise(Elang::ParsingError){_parse("00x33")}
    assert_raise(Elang::ParsingError){_parse("1x22")}
    assert_raise(Elang::ParsingError){_parse("12345x22")}
    assert_raise(Elang::ParsingError){_parse("0a")}
    assert_raise(Elang::ParsingError){_parse("0_")}
    assert_raise(Elang::ParsingError){_parse("0x")}
    assert_raise(Elang::ParsingError){_parse("0xm")}
    assert_raise(Elang::ParsingError){_parse("0x_")}
    assert_raise(Elang::ParsingError){_parse("0x.")}
    assert_raise(Elang::ParsingError){_parse("0x(")}
    assert_raise(Elang::ParsingError){_parse("0x1.2")}
    assert_raise(Elang::ParsingError){_parse("0.0.0")}
  end
  def test_parse_string
    tokens = _parse("x='I said \"hello...\", right?'")
    assert_equal 3, tokens.count
    assert_equal [:identifier, :assign, :string], tokens.map{|x|x.type}
    assert_equal "I said \"hello...\", right?", tokens[2].text
    
    tokens = _parse("'Hello \"programming\" world...'")
    assert_equal "Hello \"programming\" world...", tokens[0].text
    
    tokens = _parse("\"Hello 'programming' world...\r\n\t\"")
    assert_equal "Hello 'programming' world...\r\n\t", tokens[0].text
  end
  def test_parse_identifier
    tokens = _parse("_=2")
    assert_equal 3, tokens.count
    assert_equal [:identifier, :assign, :number], tokens.map{|x|x.type}
    
    tokens = _parse("person_2115  \t  = \t xxx")
    assert_equal 5, tokens.count
    assert_equal [:identifier, :whitespace, :assign, :whitespace, :identifier], tokens.map{|x|x.type}
  end
  def test_assign_equal
    tokens = _parse("a=b")
    assert_equal 3, tokens.count
    assert_equal "=", tokens[1].text
    
    tokens = _parse("a==b")
    assert_equal 3, tokens.count
    assert_equal "==", tokens[1].text
    
    tokens = _parse("a===b")
    assert_equal 4, tokens.count
    assert_equal "==", tokens[1].text
    assert_equal "=", tokens[2].text
  end
  def test_less_than
    tokens = _parse("a<2")
    assert_equal 3, tokens.count
    assert_equal :lt, tokens[1].type
    
    tokens = _parse("a<=2")
    assert_equal 3, tokens.count
    assert_equal :le, tokens[1].type
    assert_equal "<=", tokens[1].text
    
    tokens = _parse("a<====2")
    assert_equal 5, tokens.count
    assert_equal [:identifier, :le, :equal, :assign, :number], tokens.map{|x|x.type}
    assert_equal ["a", "<=", "==", "=", "2"], tokens.map{|x|x.text}
  end
  def test_greater_than
    tokens = _parse("a>2")
    assert_equal 3, tokens.count
    assert_equal :gt, tokens[1].type
    
    tokens = _parse("a>=2")
    assert_equal 3, tokens.count
    assert_equal :ge, tokens[1].type
    assert_equal ">=", tokens[1].text
    
    tokens = _parse("a>====2")
    assert_equal 5, tokens.count
    assert_equal [:identifier, :ge, :equal, :assign, :number], tokens.map{|x|x.type}
    assert_equal ["a", ">=", "==", "=", "2"], tokens.map{|x|x.text}
  end
  def test_and_or
    tokens = _parse("a&b")
    assert_equal 3, tokens.count
    assert_equal "&", tokens[1].text
    
    tokens = _parse("a&&b")
    assert_equal 3, tokens.count
    assert_equal "&&", tokens[1].text
    
    tokens = _parse("a&&&b")
    assert_equal 4, tokens.count
    assert_equal "&&", tokens[1].text
    assert_equal "&", tokens[2].text
    
    tokens = _parse("a|b")
    assert_equal 3, tokens.count
    assert_equal "|", tokens[1].text
    
    tokens = _parse("a||b")
    assert_equal 3, tokens.count
    assert_equal "||", tokens[1].text
    
    tokens = _parse("a|||b")
    assert_equal 4, tokens.count
    assert_equal "||", tokens[1].text
    assert_equal "|", tokens[2].text
  end
  def test_punctuations
    tests = 
      [
        [".,:;()",    [:dot, :comma, :colon, :semicolon, :lbrk, :rbrk]], 
        ["[]{}+-*",   [:lsbrk, :rsbrk, :lcbrk, :rcbrk, :plus, :minus, :star]], 
        ["/\\?!@~`",  [:slash, :bslash, :question, :exclamation, :at, :tilde, :bquote]], 
        ["$%^|||&&&", [:dollar, :percent, :xor, :oror, :or, :andand, :and]]
      ]
      
    tests.each{|t|assert_equal t[1], _parse(t[0]).map{|x|x.type}}
  end
end

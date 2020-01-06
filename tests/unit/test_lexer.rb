require 'test-unit'
require './compiler/parser'
require './compiler/lexer'

class TestLexer < Test::Unit::TestCase
  def setup
    @parser = Elang::Parser.new
    @lexer = Elang::Lexer.new
  end
  def check_expression(expression, expected_str)
    tokens = @parser.parse(expression)
    ast_nodes = @lexer.to_sexp_array(tokens)
    display = Elang::Lexer.sexp_display(ast_nodes)
    assert_equal expected_str, display
  end
  def test_simple_expression
    check_expression "", "[]"
    check_expression "1 + 2", "[[+,1,2]]"
    check_expression "1 * 2", "[[*,1,2]]"
    check_expression "a + b", "[[+,a,b]]"
    check_expression "a + 6", "[[+,a,6]]"
    check_expression "3 + c", "[[+,3,c]]"
    check_expression "1 + (32 + p)", "[[+,1,[+,32,p]]]"
  end
  def test_medium_expression
    check_expression \
      "x = 32 + p * 5 - 4 & q * r / s + 1", 
      "[[=,x,[+,32,[-,[*,p,5],[+,[/,[*,[&,4,q],r],s],1]]]]]"
    check_expression \
      "x = (32 + p) * (5 - 4) & q * r / s + 1", 
      "[[=,x,[*,[+,32,p],[+,[/,[*,[&,[-,5,4],q],r],s],1]]]]"
    check_expression \
      "x = (32 + p * (5 - sqrt(4))) & (q * r / s + 1)", 
      "[[=,x,[&,[+,32,[*,p,[-,5,[sqrt,[4]]]]],[*,q,[+,[/,r,s],1]]]]]"
    
    check_expression \
      "x = mid(text, sqrt(2), 4)", 
      "[[=,x,[mid,[text,[sqrt,[2]],4]]]]"
    
    check_expression \
      "x = 2\r\ny = 3\r\n", 
      "[[=,x,2],[=,y,3]]"
    
    check_expression \
      "def hitung\r\na = 2\r\nend\r\n", 
      "[[def,hitung,[],[[=,a,2]]]]"
    
    check_expression \
      "def hitung(text)\r\nx = mid(text, sqrt(2), 4)\r\nend", 
      "[[def,hitung,[text],[[=,x,[mid,[text,[sqrt,[2]],4]]]]]]"
  end
  def test_multiline_expression
    # check_expression "x = 32 + 5\nputs x\n", "[=,x,[+,32,5]]"
  end
  def test_multiline_complex_expression
    source = <<EOS
# function usage example
def display(info, add_new_line = false)
  puts info
  puts if add_new_line
end
def tcase(text)
  result = ''
  
  each(split(text, ' ')) do |t|
    result = result + ' ' if len(result) > 0
    result = result + ucase(part(t, 0, 1)) + part(t, 1, -1)
  end
  
  result
end

a = "hello world...".tcase
show a
EOS
  end
end

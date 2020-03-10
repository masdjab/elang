require 'test-unit'
require './compiler/exception'
require './compiler/fetcher'
require './compiler/source_code'
require './compiler/parser'
require './compiler/lexer'
require './compiler/operation'
require './compiler/shunting_yard'

class TestShuntingYard < Test::Unit::TestCase
  def setup
    @parser = Elang::Parser.new
  end
  def build(exp)
    sy = Elang::ShuntingYard.new
    lx = Elang::Lexer.new
    tt = @parser.parse(Elang::StringSourceCode.new(exp))
    nn = Elang::Lexer.convert_tokens_to_lex_nodes(tt)
    rr = sy.process(nn)
    Elang::Lexer.sexp_to_s(rr)
  end
  def check_result(expression, expected)
    assert_equal expected, build(expression)
  end
  def test_shunting_yard
  end
end

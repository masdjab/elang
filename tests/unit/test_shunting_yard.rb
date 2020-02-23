require 'test-unit'
require './compiler/exception'
require './compiler/fetcher_v2'
require './compiler/ast_node'
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
    tt = Elang::Lexer.optimize(@parser.parse(Elang::StringSourceCode.new(exp)))
    nn = Elang::Lexer.convert_tokens_to_ast_nodes(tt)
    ff = Elang::FetcherV2.new(nn)
    rr = sy.fetch_expressions(ff)
    Elang::Lexer.sexp_display(rr)
  end
  def check_result(expression, expected)
    assert_equal expected, build(expression)
  end
  def test_shunting_yard
    check_result "a+b+c", "[[+,[+,a,b],c]]"
    check_result "a+b*c", "[[+,a,[*,b,c]]]"
    check_result "a+b*c-d", "[[-,[+,a,[*,b,c]],d]]"
    check_result "a+b*c*d+e", "[[+,[+,a,[*,[*,b,c],d]],e]]"
    check_result "4&q*r", "[[&,4,[*,q,r]]]"
    check_result "1+2&3-4", "[[&,[+,1,2],[-,3,4]]]"
    check_result "1+2&3*4-5+6", "[[&,[+,1,2],[+,[-,[*,3,4],5],6]]]"
    check_result "1+2*3-4&5*6/7+8", "[[&,[-,[+,1,[*,2,3]],4],[+,[/,[*,5,6],7],8]]]"
    check_result "x=3+p*5-4&q*r/s+1", "[[=,x,[&,[-,[+,3,[*,p,5]],4],[+,[/,[*,q,r],s],1]]]]"
    check_result "3+4*2/5^2^3", "[[^,[^,[+,3,[/,[*,4,2],5]],2],3]]"
    check_result "1 + (32 + p)", "[[+,1,[+,32,p]]]"
    check_result "x = 1 + (32 + p)", "[[=,x,[+,1,[+,32,p]]]]"
    check_result "a.b+c*d.e", "[[+,[.,a,b,[]],[*,c,[.,d,e,[]]]]]"
    check_result "a.b(1)+c*d.e(2)", "[[+,[.,a,b,[1]],[*,c,[.,d,e,[2]]]]]"
    check_result "a.b(1,2)+c*d.e(3,4)", "[[+,[.,a,b,[1,2]],[*,c,[.,d,e,[3,4]]]]]"
    check_result "a = tambah(4, 3)", "[[=,a,[.,nil,tambah,[4,3]]]]"
    check_result "x = p1.get(0).phone.substr(0, 2)", "[[=,x,[.,[.,[.,p1,get,[0]],phone,[]],substr,[0,2]]]]"
    check_result "puts(3, 5)", "[[.,nil,puts,[3,5]]]"
    check_result "puts(_int_pack(2))", "[[.,nil,puts,[[.,nil,_int_pack,[2]]]]]"
    check_result "x = 32 + p * 5 - 4 & q * r / s + 1", "[[=,x,[&,[-,[+,32,[*,p,5]],4],[+,[/,[*,q,r],s],1]]]]"
    check_result "x = (32 + p) * (5 - 4) & q * r / s + 1", "[[=,x,[&,[*,[+,32,p],[-,5,4]],[+,[/,[*,q,r],s],1]]]]"
    check_result "x = (32 + p * (5 - sqrt(4))) & (q * r / s + 1)", "[[=,x,[&,[+,32,[*,p,[-,5,[.,nil,sqrt,[4]]]]],[+,[/,[*,q,r],s],1]]]]"
    check_result "x = (32 + p) * (5 - 4) & q * r / s + 1", "[[=,x,[&,[*,[+,32,p],[-,5,4]],[+,[/,[*,q,r],s],1]]]]"
    check_result "d = \"COMPUTING\"", "[[=,d,COMPUTING]]"
    check_result "puts(d.substr(1,7))", "[[.,nil,puts,[[.,d,substr,[1,7]]]]]"
    check_result "puts(d.substr(1,7).substr(2,5))", "[[.,nil,puts,[[.,[.,d,substr,[1,7]],substr,[2,5]]]]]"
    check_result "d.set_name(\"Bowo\")", "[[.,d,set_name,[Bowo]]]"
    #check_result "d.set_name \"Bowo\"", "[[.,d,set_name,[Bowo]]]"
  end
end

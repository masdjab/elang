require 'test-unit'
require './compiler/ast_node'
require './compiler/code_generator'

class TestCodeGenerator < Test::Unit::TestCase
  def setup
    @code_generator = Elang::CodeGenerator.new
  end
  def pun(x)
    Elang::AstNode.new(0, 0, :punc, x)
  end
  def idt(x)
    Elang::AstNode.new(0, 0, :identifier, x)
  end
  def num(x)
    Elang::AstNode.new(0, 0, :number, x)
  end
  def str(x)
    Elang::AstNode.new(0, 0, :string, x)
  end
  def fnp(*args)
    args.map{|x|Elang::AstNode.new(0, 0, :identifier, x)}
  end
  def lfd
    Elang::AstNode.new(0, 0, :linefeed, "\r\n")
  end
  def check_code_result(nodes, expected)
    actual = @code_generator.generate_code(nodes)
    assert_equal expected, actual
  end
  def test_simple_assignment
    check_code_result \
      [[pun("="), idt("a"), num("2")]], \
      "mov ax, 02h;mov a, ax;"
  end
  def test_simple_numeric_operation
    check_code_result \
      [[pun("="),idt("mynum"),[pun("+"),num("1"),num("2")]]], \
      "mov ax, 01h;mov cx, 02h;add ax, cx;mov mynum, ax;"
    
    check_code_result \
      [[pun("="),idt("mynum"),[pun("-"),num("1"),num("2")]]], \
      "mov ax, 01h;mov cx, 02h;sub ax, cx;mov mynum, ax;"
    
    check_code_result \
      [[pun("="),idt("mynum"),[pun("*"),num("1"),num("2")]]], \
      "mov ax, 01h;mov cx, 02h;mul ax, cx;mov mynum, ax;"
    
    check_code_result \
      [[pun("="),idt("mynum"),[pun("/"),num("1"),num("2")]]], \
      "mov ax, 01h;mov cx, 02h;div ax, cx;mov mynum, ax;"
    
    check_code_result \
      [[pun("="),idt("mynum"),[pun("&"),num("1"),num("2")]]], \
      "mov ax, 01h;mov cx, 02h;and ax, cx;mov mynum, ax;"
    
    check_code_result \
      [[pun("="),idt("mynum"),[pun("|"),num("1"),num("2")]]], \
      "mov ax, 01h;mov cx, 02h;or ax, cx;mov mynum, ax;"
    
    check_code_result \
      [[pun("="),idt("mynum"),[pun("+"),idt("v1"),idt("v2")]]], \
      "mov ax, v1;mov cx, v2;add ax, cx;mov mynum, ax;"
  end
  def test_simple_string_operation
  end
  def test_simple_function_definition
    check_code_result \
      [[idt("def"),idt("echo"),[],[]]], 
      "ret"
    
    check_code_result \
      [[idt("def"),idt("echo"),fnp,[]]], 
      "ret"
    
    check_code_result \
      [[idt("def"),idt("echo"),fnp("x"),[]]], 
      "ret 2"
    
    check_code_result \
      [[idt("def"),idt("echo"),fnp("x","y"),[]]], 
      "ret 4"
    
    check_code_result \
      [[idt("def"),idt("echo"),fnp("x","y"),[[pun("="),idt("x"),num("5")]]]], 
      "mov ax, 05h;mov x, ax;ret 4"
    
    check_code_result \
      [[
        idt("def"),idt("echo"),fnp("x","y"),
        [
          [pun("="),idt("x"),num("5")],
          [pun("="),idt("y"),num("2")]
        ]
      ]], 
      "mov ax, 05h;mov x, ax;mov ax, 02h;mov y, ax;ret 4"
  end
  def test_simple_function_call
    check_code_result \
      [[idt("call"),idt("multiply_by_two"),[num("3")]]], 
      "mov ax, 03h;push ax;call multiply_by_two;"
  end
end

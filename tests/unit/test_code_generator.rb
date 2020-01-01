require 'test-unit'
require './compiler/ast_node'
require './compiler/code_generator'
require './utils/converter'

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
  def bin(h)
    Elang::Utils::Converter.hex_to_bin(h)
  end
  def symbols
    @code_generator.symbols
  end
  def check_code_result(nodes, expected)
    actual = @code_generator.generate_code(nodes)
    assert_equal expected, actual
  end
  def test_simple_assignment
    check_code_result \
      [[pun("="), idt("a"), num("2")]], \
      # mov ax, 02h; mov a, ax"
      bin("B80200A20000")
    assert_equal 1, symbols.count
  end
  def test_simple_numeric_operation
    # mov ax, 01h; mov cx, 02h; add ax, cx; mov mynum, ax
    check_code_result \
      [[pun("="),idt("mynum"),[pun("+"),num("1"),num("2")]]], \
      bin("B80100B9020001C8A20000")
      
    # mov ax, 01h; mov cx, 02h; sub ax, cx; mov mynum, ax
    check_code_result \
      [[pun("="),idt("mynum"),[pun("-"),num("1"),num("2")]]], \
      bin("B80100B9020029C8A20000")
    
    # mov ax, 01h; mov cx, 02h; mul ax, cx; mov mynum, ax
    check_code_result \
      [[pun("="),idt("mynum"),[pun("*"),num("1"),num("2")]]], \
      bin("B80100B90200F7E9A20000")
    
    # mov ax, 01h; mov cx, 02h; div ax, cx; mov mynum, ax
    check_code_result \
      [[pun("="),idt("mynum"),[pun("/"),num("1"),num("2")]]], \
      bin("B80100B90200F7F9A20000")
    
    # mov ax, 01h; mov cx, 02h; and ax, cx; mov mynum, ax
    check_code_result \
      [[pun("="),idt("mynum"),[pun("&"),num("1"),num("2")]]], \
      bin("B80100B9020021C8A20000")
    
    # mov ax, 01h; mov cx, 02h; or ax, cx; mov mynum, ax
    check_code_result \
      [[pun("="),idt("mynum"),[pun("|"),num("1"),num("2")]]], \
      bin("B80100B9020009C8A20000")
    
    # mov ax, 0; mov v1, ax
    # mov ax, 0; mov v2, ax
    # mov ax, v1; mov cx, v2; add ax, cx; mov mynum, ax
    check_code_result \
      [
        [pun("="),idt("v1"),num("18")], 
        [pun("="),idt("v2"),num("52")], 
        [pun("="),idt("mynum"),[pun("+"),idt("v1"),idt("v2")]]
      ], \
      bin("B81200A20000B83400A20000A100008B0E000001C8A20000")
  end
  def test_simple_string_operation
  end
  def test_simple_function_definition
    # ret
    check_code_result \
      [[idt("def"),idt("echo"),[],[]]], 
      bin("C3")
    
    # ret
    check_code_result \
      [[idt("def"),idt("echo"),fnp,[]]], 
      bin("C3")
    
    # ret 2
    check_code_result \
      [[idt("def"),idt("echo"),fnp("x"),[]]], 
      bin("C20200")
    
    # ret 4
    check_code_result \
      [[idt("def"),idt("echo"),fnp("x","y"),[]]], 
      bin("C20400")
    
    # mov ax, 05h; mov x, ax; ret 4
    check_code_result \
      [[idt("def"),idt("echo"),fnp("x","y"),[[pun("="),idt("x"),num("5")]]]], 
      bin("B80500A20000C20400")
    
    # mov ax, 05h; mov x, ax; mov ax, 02h; mov y, ax; ret 4
    check_code_result \
      [[
        idt("def"),idt("echo"),fnp("x","y"),
        [
          [pun("="),idt("x"),num("5")],
          [pun("="),idt("y"),num("2")]
        ]
      ]], 
      bin("B80500A20000B80200A20000C20400")
    assert_equal 2, symbols.count
    assert_equal "x", symbols.items[0].name
    assert_equal "y", symbols.items[1].name
  end
  def test_simple_function_call
    # mov ax, 03h; push ax; call multiply_by_two
    check_code_result \
      [[idt("call"),idt("multiply_by_two"),[num("3")]]], 
      bin("B8030050E80000")
  end
end

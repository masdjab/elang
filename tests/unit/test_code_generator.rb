require 'test-unit'
require './compiler/ast_node'
require './compiler/code_generator'
require './utils/converter'

class TestCodeGenerator < Test::Unit::TestCase
  def setup
    @code_generator = Elang::CodeGenerator.new
  end
  def nd(type, value)
    Elang::AstNode.new(0, 0, type, value)
  end
  def pun(x)
    nd(:punc, x)
  end
  def asn
    nd(:assign, "=")
  end
  def plus
    nd(:plus, "+")
  end
  def minus
    nd(:minus, "-")
  end
  def star
    nd(:star, "*")
  end
  def slash
    nd(:slash, "/")
  end
  def pand
    nd(:and, "&")
  end
  def por
    nd(:or, "|")
  end
  def idt(x)
    nd(:identifier, x)
  end
  def num(x)
    nd(:number, x)
  end
  def str(x)
    nd(:string, x)
  end
  def fnp(*args)
    args.map{|x|Elang::AstNode.new(0, 0, :identifier, x)}
  end
  def dot
    nd(:dot, ".")
  end
  def lfd
    nd(:linefeed, "\r\n")
  end
  def bin(h)
    Elang::Utils::Converter.hex_to_bin(h)
  end
  def symbols
    @code_generator.symbols
  end
  def generate_code(nodes)
    @code_generator.generate_code(nodes)
  end
  def check_code_result(nodes, exp_main, exp_subs)
    codeset = generate_code(nodes)
    assert_equal exp_main, codeset.main_code
    assert_equal exp_subs, codeset.subs_code
    codeset
  end
  def test_simple_assignment
    codeset = 
      check_code_result(
        [[asn, idt("a"), num("2")]], \
        # mov ax, 02h; mov a, ax"
        bin("B80500A30000"), 
        ""
      )
    assert_equal 1, codeset.symbols.count
  end
  def test_simple_numeric_operation
    # mov ax, 01h; mov cx, 02h; add ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[plus,num("1"),num("2")]]], \
      bin("B8050050B8030050E80000A30000"), 
      ""
      
    # mov ax, 01h; mov cx, 02h; sub ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[minus,num("1"),num("2")]]], \
      bin("B8050050B8030050E80000A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; mul ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[star,num("1"),num("2")]]], \
      bin("B8050050B8030050E80000A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; div ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[slash,num("1"),num("2")]]], \
      bin("B8050050B8030050E80000A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; and ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[pand,num("1"),num("2")]]], \
      bin("B8050050B8030050E80000A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; or ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[por,num("1"),num("2")]]], \
      bin("B8050050B8030050E80000A30000"), 
      ""
    
    # mov ax, 0; mov v1, ax
    # mov ax, 0; mov v2, ax
    # mov ax, v1; mov cx, v2; add ax, cx; mov mynum, ax
    check_code_result \
      [
        [asn,idt("v1"),num("18")], 
        [asn,idt("v2"),num("52")], 
        [asn,idt("mynum"),[plus,idt("v1"),idt("v2")]]
      ], \
      bin("B82500A30000B86900A30000A1000050A1000050E80000A30000"), 
      ""
  end
  def test_simple_string_operation
    #(todo)#test_simple_string_operation
  end
  def test_simple_function_definition
    # ret
    check_code_result \
      [[idt("def"),nil,idt("echo"),[],[]]], 
      "", 
      bin("5589E55DC3")
    
    # ret
    check_code_result \
      [[idt("def"),nil,idt("echo"),fnp,[]]], 
      "", 
      bin("5589E55DC3")
    
    # ret 2
    check_code_result \
      [[idt("def"),nil,idt("echo"),fnp("x"),[]]], 
      "", 
      bin("5589E55DC20200")
    
    # ret 4
    check_code_result \
      [[idt("def"),nil,idt("echo"),fnp("x","y"),[]]], 
      "", 
      bin("5589E55DC20400")
    
    # mov ax, 05h; mov x, ax; ret 4
    check_code_result \
      [[idt("def"),nil,idt("echo"),fnp("x","y"),[[asn,idt("x"),num("5")]]]], 
      "", 
      bin("5589E5B80B008946005DC20400")
    
    # mov ax, 05h; mov x, ax; mov ax, 02h; mov y, ax; ret 4
    codeset = 
      check_code_result(
        [
          [
            idt("def"),nil,idt("echo"),fnp("x","y"),
            [
              [asn,idt("a"),num("5")],
              [asn,idt("b"),num("2")]
            ]
          ]
        ], 
        "", 
        bin("5589E5B80B00894600B805008946005DC20400")
      )
    assert_equal 5, codeset.symbols.count
    assert_equal "echo", codeset.symbols.items[0].name
    assert_equal "x", codeset.symbols.items[1].name
    assert_equal "y", codeset.symbols.items[2].name
    assert_equal "a", codeset.symbols.items[3].name
    assert_equal "b", codeset.symbols.items[4].name
  end
  def test_simple_function_call
    check_code_result \
      [
        [
          idt("def"),nil,idt("tambah"),fnp("a","b"),
          [
            [plus,idt("a"),idt("b")]
          ]
        ], 
        [asn,idt("a"),[idt("tambah"),[num("4"),num("3")]]]
      ], 
      bin("B8070050B8090050E80000A30000"), 
      bin("5589E58B4600508B460050E800005DC20400")
    
    # mov ax, 03h; push ax; call multiply_by_two
    codeset = 
      check_code_result \
        [
          [idt("def"),nil,idt("multiply_by_two"),fnp("x"),[]], 
          [idt("multiply_by_two"),[num("3")]]
        ], 
        bin("B8070050E80000"), 
        bin("5589E55DC20200")
    functions = codeset.symbols.items.select{|x|x.is_a?(Elang::Function)}
    assert_equal 1, functions.count
    assert_equal "multiply_by_two", functions[0].name
  end
  def test_function_parameter
    # root function parameter
    # mov ax, [bp - 0]; push ax; call multiply_by_two
    check_code_result \
      [
        [idt("def"),nil,idt("multiply_by_two"),fnp("x", "y"),[]], 
        [asn, idt("x"), num("2")], 
        [asn, idt("y"), num("3")], 
        [idt("multiply_by_two"),[idt("x"), idt("y")]]
      ], 
      bin("B80500A30000B80700A30000A1000050A1000050E80000"), 
      bin("5589E55DC20400")
    
    # instance function parameter
    # mov ax, [bp - 2]; push ax; call multiply_by_two
    check_code_result \
      [
        [
          idt("class"),idt("Math"),nil, 
          [
            [
              idt("def"),nil,idt("multiply_by_two"),fnp("x", "y"),
              [
                [idt("multiply_by_two"),[idt("x"), idt("y")]]
              ]
            ]
          ]
        ], 
        [asn,idt("p1"), [dot, idt("Math"), idt("new"), []]], 
        [asn,idt("x"), num("2")], 
        [asn,idt("y"), num("3")], 
        [dot,idt("p1"),idt("multiply_by_two"),[idt("x"), idt("y")]]
      ], 
      bin("B8000050B80B0050E80000A30000B80500A30000B80700A30000A1000050A1000050B8020050B8000050A1000050E80000"), 
      bin("8B4600508B460050E80000C3")
  end
  def test_function_local_var
    # root function local var
    # mov ax, [bp + 4]; push ax; call multiply_by_two
    check_code_result \
      [
        [
          idt("def"),nil,idt("multiply_by_two"),fnp("x"),
          [
            [asn,idt("a"),num("2")], 
            [idt("multiply_by_two"),[idt("a")]]
          ]
        ]
      ], 
      "", 
      bin("5589E5B805008946008B460050E800005DC20200")
    
    # instance function local var
    # mov ax, [bp + 6]; push ax; call multiply_by_two
    check_code_result \
      [
        [idt("class"),idt("Math"),nil, 
          [
            [
              idt("def"),nil,idt("multiply_by_two"),fnp("x"),
              [
                [asn,idt("a"),num("2")], 
                [idt("multiply_by_two"),[idt("a")]]
              ]
            ]
          ]
        ]
      ], 
      "", 
      bin("B805008946008B460050E80000C3")
  end
  def test_instance_variable
    # instance function local var
    check_code_result \
      [
        [idt("class"),idt("Person"),nil, 
          [
            [
              idt("def"),nil,idt("set_name"),fnp("name"),
              [
                [asn,idt("@name"),idt("name")]
              ]
            ],
            [
              idt("def"),nil,idt("get_name"),[],
              [
                [idt("@name")]
              ]
            ]
          ]
        ]
      ], 
      "", 
      bin("8B460050B80000508B460450E80000C3B80000508B460450E80000C3")
  end
  def test_class_definition
    codeset = 
      generate_code \
        [
          [idt("class"), idt("Integer"), idt("nil"), []], 
          [idt("class"), idt("TrueClass"), idt("nil"), []], 
          [idt("class"), idt("FalseClass"), idt("nil"), []]
        ]
    
    classes = codeset.symbols.items.select{|x|x.is_a?(Elang::Class)}
    assert_equal 3, classes.count
    assert_equal [], classes.map{|x|x.name} - ["Integer", "TrueClass", "FalseClass"]
  end
  def test_class_function_call
    #(todo)#test_class_function_call
  end
  def test_class_variabel
    #(todo)#test_class_variable
  end
end

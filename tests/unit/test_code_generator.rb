require 'test-unit'
require './compiler/exception'
require './compiler/source_code'
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
  def generate_code(nodes, source = nil)
    codeset = Elang::CodeSet.new
    @code_generator.generate_code(nodes, codeset, source)
    codeset
  end
  def check_code_result(nodes, exp_main, exp_subs, source = nil)
    codeset = generate_code(nodes, source)
    assert_equal exp_main, codeset.main_code
    assert_equal exp_subs, codeset.subs_code
    codeset
  end
  def test_simple_assignment
    codeset = 
      check_code_result(
        [[asn, idt("a"), num("2")]], \
        # mov ax, 02h; mov a, ax"
        bin("B8050050A1000050E8000058A30000"), 
        ""
      )
    assert_equal 1, codeset.symbols.count
  end
  def test_simple_numeric_operation
    # mov ax, 01h; mov cx, 02h; add ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[dot,num("1"),plus,[num("2")]]]], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
      
    # mov ax, 01h; mov cx, 02h; sub ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[dot,num("1"),minus,[num("2")]]]], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; mul ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[dot,num("1"),star,[num("2")]]]], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; div ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[dot,num("1"),slash,[num("2")]]]], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; and ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[dot,num("1"),pand,[num("2")]]]], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; or ax, cx; mov mynum, ax
    check_code_result \
      [[asn,idt("mynum"),[dot,num("1"),por,[num("2")]]]], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 0; mov v1, ax
    # mov ax, 0; mov v2, ax
    # mov ax, v1; mov cx, v2; add ax, cx; mov mynum, ax
    check_code_result \
      [
        [asn,idt("v1"),num("18")], 
        [asn,idt("v2"),num("52")], 
        [asn,idt("mynum"),[dot,idt("v1"),plus,[idt("v2")]]]
      ], \
      bin("B8250050A1000050E8000058A30000B8690050A1000050E8000058A30000A1000050B8010050B8000050A1000050E8000050A1000050E8000058A30000"), 
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
      bin("5589E5B80B00508B460050E80000588946005DC20400")
    
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
        bin(
          "5589E581EC040031C089460031C0894600B80B00508B460050E8" \
          "000058894600B80500508B460050E8000058894600508B460050E8" \
          "00008B460050E800005881C404005DC20400"
        )
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
            [dot,idt("a"),plus,[idt("b")]]
          ]
        ], 
        [asn,idt("a"),[idt("tambah"),[num("4"),num("3")]]]
      ], 
      bin("B8070050B8090050E8000050A1000050E8000058A30000"), 
      bin("5589E58B460050B8010050B80000508B460050E800005DC20400")
    
    # mov ax, 03h; push ax; call multiply_by_two
    codeset = 
      check_code_result \
        [
          [idt("def"),nil,idt("multiply_by_two1"),fnp("x"),[]], 
          [idt("multiply_by_two1"),[num("3")]]
        ], 
        bin("B8070050E80000"), 
        bin("5589E55DC20200")
    functions = codeset.symbols.items.select{|x|x.is_a?(Elang::Function)}
    assert_equal 1, functions.count
    assert_equal "multiply_by_two1", functions[0].name
    
    check_code_result \
      [[asn,idt("a"),[dot,num(1),plus,[num(1)]]],[dot,nil,idt("puts"),[[dot,str("1 + 1 = "),plus,[[dot,idt("a"),idt("to_s"),[]]]]]]], 
      bin("B8030050B8010050B8000050B8030050E8000050A1000050E8000058A30000B8000050B8000050A1000050E8000050B8010050B8000050BE00008B440083C6025056E8000050E8000050E80000"), 
      ""
  end
  def test_function_parameter
    # root function parameter
    # mov ax, [bp - 0]; push ax; call multiply_by_two
    check_code_result \
      [
        [idt("def"),nil,idt("multiply_by_two2"),fnp("x", "y"),[]], 
        [asn, idt("x"), num("2")], 
        [asn, idt("y"), num("3")], 
        [dot,nil,idt("multiply_by_two2"),[idt("x"), idt("y")]]
      ], 
      bin("B8050050A1000050E8000058A30000B8070050A1000050E8000058A30000A1000050A1000050E80000"), 
      bin("5589E55DC20400")
    
    # instance function parameter
    # mov ax, [bp - 2]; push ax; call multiply_by_two
    check_code_result \
      [
        [
          idt("class"),idt("Math"),nil, 
          [
            [
              idt("def"),nil,idt("multiply_by_two3"),fnp("x", "y"),
              [
                [dot,nil,idt("multiply_by_two3"),[idt("x"), idt("y")]]
              ]
            ]
          ]
        ], 
        [asn,idt("p1"), [dot, idt("Math"), idt("new"), []]], 
        [asn,idt("x"), num("2")], 
        [asn,idt("y"), num("3")], 
        [dot,idt("p1"),idt("multiply_by_two3"),[idt("x"), idt("y")]]
      ], 
      bin("B8000050B80B0050E8000050A1000050E8000058A30000B8050050A1000050E8000058A30000B8070050A1000050E8000058A30000A1000050A1000050B8020050B8000050A1000050E80000"), 
      bin("8B4600508B460050B8020050B80000508B460450E80000C3")
  end
  def test_function_local_var
    # root function local var
    # mov ax, [bp + 4]; push ax; call multiply_by_two
    check_code_result \
      [
        [
          idt("def"),nil,idt("multiply_by_two4"),fnp("x"),
          [
            [asn,idt("a"),num("2")], 
            [idt("multiply_by_two4"),[idt("a")]]
          ]
        ]
      ], 
      "", 
      bin(
        "5589E581EC020031C0894600B80500508B460050E8000058" \
        "8946008B460050E80000508B460050E800005881C402005DC20200"
      )
    
    # instance function local var
    # mov ax, [bp + 6]; push ax; call multiply_by_two
    check_code_result \
      [
        [idt("class"),idt("Math"),nil, 
          [
            [
              idt("def"),nil,idt("multiply_by_two5"),fnp("x"),
              [
                [asn,idt("a"),num("2")], 
                [idt("multiply_by_two5"),[idt("a")]]
              ]
            ]
          ]
        ]
      ], 
      "", 
      bin(
        "81EC020031C0894600B80500508B460050E8000058894600" \
        "8B460050E80000508B460050E800005881C40200C3"
      )
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
          [idt("class"), idt("Integer"), nil, []], 
          [idt("class"), idt("TrueClass"), nil, []], 
          [idt("class"), idt("FalseClass"), nil, []]
        ]
    
    classes = codeset.symbols.items.select{|x|x.is_a?(Elang::Class)}
    assert_equal 3, classes.count
    assert_equal [], classes.map{|x|x.name} - ["Integer", "TrueClass", "FalseClass"]
    
    
    check_code_result \
      [
        [idt("def"), nil, idt("i2s"), [idt("v")], []], 
        [idt("def"), nil, idt("iunpack"), [idt("v")], []], 
        [
          idt("class"), idt("Integer"), nil, 
          [
            [
              idt("def"), nil, idt("to_s"), [], 
              [
                [dot,nil,idt("i2s"), [[dot,nil,idt("iunpack"), [num("8")]]]]
              ]
            ]
          ]
        ]
      ], 
      "", 
      bin("5589E55DC202005589E55DC20200B8110050E8000050E80000C3")
  end
  def test_class_function_call
    #(todo)#test_class_function_call
  end
  def test_class_variabel
    #(todo)#test_class_variable
  end
end

require 'test-unit'
require './compiler/code'
require './compiler/kernel'
require './compiler/exception'
require './compiler/source_code'
require './compiler/lex'
require './compiler/symbol/_load'
require './compiler/codepad'
require './compiler/code_section'
require './compiler/scope'
require './compiler/scope_stack'
require './compiler/language/_load'
require './compiler/name_detector'
require './compiler/language/_load'
require './compiler/code_generator/_load'
require './compiler/converter'
require './compiler/build_config'


class TestCodeGenerator < Test::Unit::TestCase
  def nd(type, value)
    Elang::Lex::Node.new(0, 0, nil, type, value)
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
    args.map{|x|Elang::Lex::Node.new(0, 0, :identifier, x)}
  end
  def dot
    nd(:dot, ".")
  end
  def lfd
    nd(:linefeed, "\r\n")
  end
  def clas(name, parent, body)
    Elang::Lex::Class.new(name, parent, body)
  end
  def func(receiver, name, params, body)
    Elang::Lex::Function.new(receiver, name, params, body)
  end
  def send(receiver, cmd, args)
    Elang::Lex::Send.new(receiver, cmd, args)
  end
  def bin(h)
    Elang::Converter.hex2bin(h)
  end
  def generate_code(nodes, source = nil)
    @build_config = Elang::BuildConfig.new
    @build_config.kernel = Elang::Kernel.load_library("./libs/libmsdos.bin")
    @build_config.symbols = Elang::Symbols.new
    @build_config.symbol_refs = []
    @build_config.codeset = {}
    @build_config.code_origin = 0x100
    @build_config.heap_size = 0x8000
    @build_config.first_block_offs = 0
    @build_config.reserved_var_count = Elang::Variable::RESERVED_VARIABLE_COUNT
    
    @language = Elang::Language::Intel16.new(@build_config)
    @code_generator = Elang::CodeGenerator::Intel.new(@build_config.symbols, @language)
    Elang::NameDetector.new(@build_config.symbols).detect_names nodes
    @code_generator.generate_code(nodes)
    @build_config.codeset
  end
  def check_code_result(nodes, exp_main, exp_subs, source = nil)
    codeset = generate_code(nodes, source)
    assert_equal exp_main, codeset["main"].data
    assert_equal exp_subs, codeset["subs"].data
    codeset
  end
  def test_simple_assignment
    codeset = 
      check_code_result(
        [send(idt("a"),asn,num("2"))], \
        # mov ax, 02h; mov a, ax"
        bin("B8050050A1000050E8000058A30000"), 
        ""
      )
    assert_equal 1, @build_config.symbols.count
  end
  def test_simple_numeric_operation
    # mov ax, 01h; mov cx, 02h; add ax, cx; mov mynum, ax
    check_code_result \
      [send(idt("mynum"),asn,[send(num("1"),plus,[num("2")])])], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
      
    # mov ax, 01h; mov cx, 02h; sub ax, cx; mov mynum, ax
    check_code_result \
      [send(idt("mynum"),asn,[send(num("1"),minus,[num("2")])])], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; mul ax, cx; mov mynum, ax
    check_code_result \
      [send(idt("mynum"),asn,[send(num("1"),star,[num("2")])])], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; div ax, cx; mov mynum, ax
    check_code_result \
      [send(idt("mynum"),asn,[send(num("1"),slash,[num("2")])])], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; and ax, cx; mov mynum, ax
    check_code_result \
      [send(idt("mynum"),asn,[send(num("1"),pand,[num("2")])])], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 01h; mov cx, 02h; or ax, cx; mov mynum, ax
    check_code_result \
      [send(idt("mynum"),asn,[send(num("1"),por,[num("2")])])], \
      bin("B8050050B8010050B8000050B8030050E8000050A1000050E8000058A30000"), 
      ""
    
    # mov ax, 0; mov v1, ax
    # mov ax, 0; mov v2, ax
    # mov ax, v1; mov cx, v2; add ax, cx; mov mynum, ax
    check_code_result \
      [
        send(idt("v1"),asn,[num("18")]), 
        send(idt("v2"),asn,[num("52")]), 
        send(idt("mynum"),asn,[send(idt("v1"),plus,[idt("v2")])])
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
      [func(nil,idt("echo"),[],[])], 
      "", 
      bin("5589E55DC3")
    
    # ret 2
    check_code_result \
      [func(nil,idt("echo"),[idt("x")],[])], 
      "", 
      bin("5589E55DC20200")
    
    # ret 4
    check_code_result \
      [func(nil,idt("echo"),[idt("x"),idt("y")],[])], 
      "", 
      bin("5589E55DC20400")
    
    # mov ax, 05h; mov x, ax; ret 4
    check_code_result \
      [func(nil,idt("echo"),[idt("x"),idt("y")],[send(idt("x"),asn,num("5"))])], 
      "", 
      bin("5589E5B80B00508B460050E80000588946005DC20400")
    
    # mov ax, 05h; mov x, ax; mov ax, 02h; mov y, ax; ret 4
    codeset = 
      check_code_result(
        [
          func(nil,idt("echo"),[idt("x"),idt("y")],
            [
              send(idt("a"),asn,num("5")),
              send(idt("b"),asn,num("2"))
            ]
          )
        ], 
        "", 
        bin(
          "5589E581EC040031C089460031C0894600B80B00508B460050E8" \
          "000058894600B80500508B460050E8000058894600508B460050E8" \
          "00008B460050E800005881C404005DC20400"
        )
      )
    assert_equal 5, @build_config.symbols.count
    assert_equal "echo", @build_config.symbols.items[0].name
    assert_equal "x", @build_config.symbols.items[1].name
    assert_equal "y", @build_config.symbols.items[2].name
    assert_equal "a", @build_config.symbols.items[3].name
    assert_equal "b", @build_config.symbols.items[4].name
  end
  def test_simple_function_call
    check_code_result \
      [
        func(nil,idt("tambah"),[idt("a"),idt("b")],[send(idt("a"),plus,[idt("b")])]), 
        send(idt("a"),asn,[send(nil,idt("tambah"),[num("4"),num("3")])])
      ], 
      bin("B8070050B8090050E8000050A1000050E8000058A30000"), 
      bin("5589E58B460050B8010050B80000508B460050E800005DC20400")
    
    # mov ax, 03h; push ax; call multiply_by_two
    codeset = 
      check_code_result \
        [
          func(nil,idt("multiply_by_two1"),[idt("x")],[]), 
          send(nil,idt("multiply_by_two1"),[num("3")])
        ], 
        bin("B8070050E80000"), 
        bin("5589E55DC20200")
    functions = @build_config.symbols.items.select{|x|x.is_a?(Elang::Function)}
    assert_equal 1, functions.count
    assert_equal "multiply_by_two1", functions[0].name
    
    check_code_result \
      [
        send(idt("a"),asn,send(num("1"),plus,[num("1")])),
        send(nil,idt("puts"),[send(str("1 + 1 = "),plus,[send(idt("a"),idt("to_s"),[])])])
      ], 
      bin(
        "B8030050B8010050B8000050B8030050E8000050A1000050E8000058A30000" \
        "B8000050B8000050A1000050E8000050B8010050B8000050B8000050E8000050E8000050E80000"
      ), 
      ""
  end
  def test_function_parameter
    # root function parameter
    # mov ax, [bp - 0]; push ax; call multiply_by_two
    check_code_result \
      [
        func(nil, idt("multiply_by_two2"), [idt("x"),idt("y")], []), 
        send(idt("x"), asn, [num("2")]), 
        send(idt("y"), asn, [num("3")]), 
        send(nil, idt("multiply_by_two2"), [idt("x"), idt("y")])
      ], 
      bin("B8050050A1000050E8000058A30000B8070050A1000050E8000058A30000A1000050A1000050E80000"), 
      bin("5589E55DC20400")
    
    # instance function parameter
    # mov ax, [bp - 2]; push ax; call multiply_by_two
    check_code_result \
      [
        clas(
          idt("Math"), nil, 
          [
            func(nil, idt("multiply_by_two3"), [idt("x"), idt("y")], 
              [send(nil, idt("multiply_by_two3"), [idt("x"), idt("y")])]
            )
          ]
        ), 
        send(idt("p1"), asn, send(idt("Math"), idt("new"), [])), 
        send(idt("x"), asn, [num("2")]), 
        send(idt("y"), asn, [num("3")]), 
        send(idt("p1"), idt("multiply_by_two3"), [idt("x"), idt("y")])
      ], 
      bin(
        "B8000050B8000150E8000050A1000050E8000058A30000B8050050A1000050E8000058A30000" \
        "B8070050A1000050E8000058A30000A1000050A1000050B8020050B8000050A1000050E80000"
      ), 
      bin("8B4600508B460050B8020050B80000508B460450E80000C3")
  end
  def test_function_local_var
    # root function local var
    # mov ax, [bp + 4]; push ax; call multiply_by_two
    check_code_result \
      [
        func(nil, idt("multiply_by_two4"), [idt("x")],
          [
            send(idt("a"), asn, [num("2")]), 
            send(nil, idt("multiply_by_two4"), [idt("a")])
          ]
        )
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
        clas(idt("Math"), nil, 
          [
            func(nil, idt("multiply_by_two5"), [idt("x")], 
              [
                send(idt("a"), asn, [num("2")]), 
                send(nil, idt("multiply_by_two5"), [idt("a")])
              ]
            )
          ]
        )
      ], 
      "", 
      bin(
        "81EC020031C0894600B80500508B460050E8000058894600" \
        "8B460050B8010050B80000508B460450E80000508B460050E8000058" \
        "81C40200C3"
      )
  end
  def test_instance_variable
    # instance function local var
    check_code_result \
      [
        clas(idt("Person"), nil, 
          [
            func(nil, idt("set_name"), [idt("name")], [send(idt("@name"), asn, [idt("name")])]),
            func(nil, idt("get_name"), [], [idt("@name")])
          ]
        )
      ], 
      "", 
      bin("8B460050B80000508B460450E80000C3B80000508B460450E80000C3")
  end
  def test_class_definition
    codeset = 
      generate_code \
        [
          clas(idt("Integer"), nil, []), 
          clas(idt("TrueClass"), nil, []), 
          clas(idt("FalseClass"), nil, [])
        ]
    
    classes = @build_config.symbols.items.select{|x|x.is_a?(Elang::Class)}
    assert_equal 3, classes.count
    assert_equal [], classes.map{|x|x.name} - ["Integer", "TrueClass", "FalseClass"]
    
    
    check_code_result \
      [
        func(nil, idt("i2s"), [idt("v")], []), 
        func(nil, idt("iunpack"), [idt("v")], []), 
        clas(idt("Integer"), nil, 
          [
            func(nil, idt("to_s"), [], 
              [
                send(nil, idt("i2s"), [send(nil, idt("iunpack"), [num("8")])])
              ]
            )
          ]
        )
      ], 
      "", 
      bin("5589E55DC202005589E55DC20200B8110050E8000050E80000C3")
    
    
    check_code_result \
      [
        func(nil, idt("iunpack"), [idt("v")], []), 
        clas(idt("Integer"), nil, 
          [
            func(nil, idt("unpack_me"), [], 
              [send(nil, idt("iunpack"), [idt("self")])]
            )
          ]
        )
      ], 
      "", 
      bin("5589E55DC202008B460450E80000C3")
  end
  def test_class_function_call
    #(todo)#test_class_function_call
  end
  def test_class_variabel
    #(todo)#test_class_variable
  end
end

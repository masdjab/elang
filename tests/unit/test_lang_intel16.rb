require 'test-unit'
require './compiler/converter'
require './compiler/code'
require './compiler/kernel'
require './compiler/symbol/_load'
#require './compiler/codeset'
require './compiler/scope'
require './compiler/scope_stack'
require './compiler/language/_load'


class TestLangIntel16 < Test::Unit::TestCase
  def setup
    @kernel = Elang::Kernel.load_library("libs/stdlib16.bin")
    @symbols = Elang::Symbols.new
    @symbol_refs = []
    @codeset = {}
    @language = Elang::Language::Intel16.new(@kernel, @symbols, @symbol_refs, @codeset)
  end
  def check_bin(actual, expected)
    @codeset = {}
    assert_equal actual, Elang::Converter.hex2bin(expected)
  end
  def test_load_immediate
    check_bin @language.load_immediate(0), "B80100"
    check_bin @language.load_immediate(0x2000), "B80140"
  end
  def test_load_str
    check_bin @language.load_str(""), "B8000050E80000"
  end
  def test_get_global_variable
    check_bin @language.get_global_variable(nil), "A10000"
  end
  def test_set_global_variable
    check_bin @language.set_global_variable(nil), "50A1000050E8000058A30000"
  end
  def test_get_local_variable
    check_bin @language.get_local_variable(nil), "8B4500"
  end
  def test_set_local_variable
    check_bin @language.set_local_variable(nil), "508B450050E8000058894500"
  end
  def test_get_instance_variable
    check_bin @language.get_instance_variable(nil), "B80000508B450450E80000"
  end
  def test_set_instance_variable
    check_bin @language.set_instance_variable(nil), "50B80000508B450450E80000"
  end
  def test_get_parameter_by_index(index)
    check_bin @language.get_parameter_by_index(0), "8B4500"
  end
  def test_get_parameter_by_symbol
    check_bin @language.get_parameter_by_symbol(nil), "8B4500"
  end
  def test_get_class
    check_bin @language.get_class(nil), "A40000"
  end
  def test_set_class
    check_bin @language.set_class(nil), "A70000"
  end
  def test_get_method_id
    check_bin @language.get_method_id(""), "B80000"
  end
  def test_push_argument
    check_bin @language.push_argument, "50"
  end
  def test_call_function
    check_bin @language.call_function(nil), "E80000"
  end
  def test_call_sys_function
    check_bin @language.call_sys_function(""), "E80000"
  end
  def test_create_object
    check_bin @language.create_object(Elang::Class.new(Elang::Scope.new, 'Person', nil, 1)), "B8000050B8010050E80000"
  end
=begin
  def test_begin_function
    #if scope.cls.nil?
    #  # push bp; mov bp, sp
    #  append_code hex2bin("55" + "89E5")
    #end
    
    #if (var_count = variables.count) > 0
    #  # sub sp, nn
    #  append_code hex2bin("83EC" + Elang::Converter.int2hex(var_count * 2, :word, :be))
      
    #  variables.each do |v|
    #    # xor ax, ax; mov [v], ax
    #    add_variable_ref v, code_len + 4
    #    append_code hex2bin("31C0894500")
    #  end
    #end
    
    #check_bin @language.begin_function(Elang::Scope.new, []), "5589E5"
    #check_bin @language.begin_function(Elang::Scope.new, [nil]), "5589E583EC0431C0894500"
  end
  def end_function(scope, params_count, variables)
    if (var_count = variables.count) > 0
      append_code hex2bin("50")
      variables.each do |v|
        # mov ax, [v]; push v; call _unassign_object
        add_variable_ref v, code_len + 2
        add_function_ref get_sys_function("_unassign_object"), code_len + 5
        append_code hex2bin("8B450050E80000")
      end
      append_code hex2bin("58")
      
      # add sp, nn
      append_code hex2bin("83C4" + Elang::Converter.int2hex(var_count * 2, :dword, :be))
    end
    
    if scope.cls.nil?
      # pop bp
      append_code hex2bin("5D")
      
      # ret [n]
      hex_code = (params_count > 0 ? "C2#{Elang::Converter.int2hex(params_count * 2, :word, :be).upcase}" : "C3")
      append_code hex2bin(hex_code)
    else
      # ret
      append_code hex2bin("C3")
    end
  end
  def begin_array
    add_function_ref get_sys_function("_create_array"), code_len + 1
    append_code hex2bin("E80000")
    
    # push dx; mov dx, ax
    append_code hex2bin("5289C2")
  end
  def array_append_item
    add_function_ref get_sys_function("_array_append"), code_len + 3
    append_code hex2bin("5052E80000")
  end
  def end_array
    # pop dx
    append_code hex2bin("5A")
  end
  def jump(target)
    jmp_to = Converter.int2hex(target - (code_len + 3), :word, :be)
    append_code hex2bin("E9#{jmp_to}")
  end
  def enter_breakable_block
    @break_stack << []
  end
  def leave_breakable_block
    @break_stack.pop
  end
  def break_block
    append_break
    append_code hex2bin("E90000")
  end
  def resolve_breaks
    break_requests.each do |b|
      jmp_distance = code_len - (b + 3)
      @codeset.code[@codeset.branch][b + 1, 2] = Converter.int2bin(jmp_distance, :word)
    end
  end
=end
end

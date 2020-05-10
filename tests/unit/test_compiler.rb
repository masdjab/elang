require 'test-unit'
require './compiler/code'
require './compiler/kernel'
require './compiler/source_code'
#require './compiler/codeset'
require './compiler/language/_load'
require './compiler/compiler'

class CompilerTest < Test::Unit::TestCase
  def compile(source_text)
    build_config = Elang::BuildConfig.new
    build_config.kernel = Elang::Kernel.load_library("./libs/libmsdos.bin")
    build_config.symbols = Elang::Symbols.new
    build_config.symbol_refs = []
    build_config.codeset = {}
    build_config.code_origin = 0x100
    build_config.heap_size = 0x8000
    build_config.first_block_offs = 0
    build_config.reserved_var_count = Elang::Variable::RESERVED_VARIABLE_COUNT
    
    source = Elang::StringSourceCode.new(source_text)
    symbols = Elang::Symbols.new
    symbol_refs = []
    parser = Elang::Parser.new
    lexer = Elang::Lexer.new
    name_detector = Elang::NameDetector.new(build_config.symbols)
    language = Elang::Language::Intel16.new(build_config)
    codegen = Elang::CodeGenerator::Intel.new(build_config.symbols, language)
    
    tokens = parser.parse(source)
    nodes = lexer.to_sexp_array(tokens)
    name_detector.detect_names(nodes)
    codegen.generate_code(nodes)
    build_config.codeset
  end
  def check_binary(actual, expected_str)
    assert_equal Elang::Converter.hex2bin(expected_str), actual
  end
  def test_link_main_code
    source = "x = 2\r\ny = 3\r\nz = x + y\r\n"
    codeset = compile(source)
    check_binary codeset["subs"].data, ""
    check_binary codeset["main"].data, "B8050050A1000050E8000058A30000B8070050A1000050E8000058A30000A1000050B8010050B8000050A1000050E8000050A1000050E8000058A30000"
  end
  def test_link_simple_combination
    source = <<EOS
def multiply_by_two(x)
  x + 1
end

a = multiply_by_two(2)
b = multiply_by_two(a)
EOS
    
    codeset = compile(source)
    check_binary codeset["subs"].data, "5589E5B8030050B8010050B80000508B460050E800005DC20200"
    check_binary codeset["main"].data, "B8050050E8000050A1000050E8000058A30000A1000050E8000050A1000050E8000058A30000"
  end
  def test_link_methods
    source = <<EOS
class Person
  def get_name
    @name
  end
  def set_name(v)
    @name = v
  end
  def self.get_person_name(person)
    person.get_name
  end
  def self.set_person_name(person, name)
    person.set_name(name)
  end
end

def test_person
  p1 = Person.new
  p1.set_name "Bowo"
  a = p1.get_name
  b = Person.set_person_name(p1, "Agus")
  c = Person.get_person_name(p1)
end

test_person
EOS
    
    #check_output \
    #  source, 
    # ""
  end
end

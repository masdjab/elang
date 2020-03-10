require 'test-unit'
require './compiler/source_code'
require './compiler/codeset/_load'
require './compiler/language/_load'
require './compiler/compiler'

class CompilerTest < Test::Unit::TestCase
  def compile(source_text)
    source = Elang::StringSourceCode.new(source_text)
    symbols = Elang::Symbols.new
    parser = Elang::Parser.new
    lexer = Elang::Lexer.new
    name_detector = Elang::NameDetector.new(symbols)
    codeset = Elang::Codeset::Binary.new
    language = Elang::Language::Machine.new(symbols, codeset)
    codegen = Elang::CodeGenerator.new(language)
    
    tokens = parser.parse(source)
    nodes = lexer.to_sexp_array(tokens)
    name_detector.detect_names(nodes)
    codegen.generate_code(nodes)
    codeset
  end
  def check_binary(actual, expected_str)
    assert_equal Elang::Utils::Converter.hex_to_bin(expected_str), actual
  end
  def test_link_main_code
    source = "x = 2\r\ny = 3\r\nz = x + y\r\n"
    codeset = compile(source)
    check_binary codeset.code[:subs], ""
    check_binary codeset.code[:main], "B8050050A1000050E8000058A30000B8070050A1000050E8000058A30000A1000050B8010050B8000050A1000050E8000050A1000050E8000058A30000"
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
    check_binary codeset.code[:subs], "5589E5B8030050B8010050B80000508B460050E800005DC20200"
    check_binary codeset.code[:main], "B8050050E8000050A1000050E8000058A30000A1000050E8000050A1000050E8000058A30000"
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

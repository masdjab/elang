require 'test-unit'
require './compiler/compiler'

class CompilerTest < Test::Unit::TestCase
  def setup
    @compiler = Elang::Compiler.new
  end
  def compile(source)
    @compiler.compile(source)
  end
  def check_binary(actual, expected_str)
    assert_equal Elang::Utils::Converter.hex_to_bin(expected_str), actual
  end
  def test_link_main_code
    source = "x = 2\r\ny = 3\r\nz = x + y\r\n"
    codeset = compile(source)
    check_binary codeset.subs_code, ""
    check_binary codeset.main_code, "b80500a30000b80700a30000a1000050a1000050e84180a30000"
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
    check_binary codeset.subs_code, "5589e58B460050b8030050e841805dc20200"
    check_binary codeset.main_code, "b8050050e80000a30000a1000050e80000a30000"
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

require 'test-unit'
require './compiler/compiler'

class CompilerTest < Test::Unit::TestCase
  def setup
    @compiler = Elang::Compiler.new
  end
  def check_output(source, expected_hex)
    output = @compiler.compile(source)
    assert_equal Elang::Utils::Converter.hex_to_bin(expected_hex), output
  end
  def test_link_main_code
    check_output \
      "x = 2\r\ny = 3\r\nz = x + y\r\n", 
      "b80200a20000b80300a20200a100008b0e020001c8a20400"
  end
  def test_link_simple_combination
    source = <<EOS
def multiply_by_two(x)
  x + 0
end

a = multiply_by_two(2)
b = multiply_by_two(a)
EOS
    check_output \
      source, 
      "e90000a10000b9000001c8c20200b8020050e8eeffa20200a1020050e8e4ffa20400"
  end
end

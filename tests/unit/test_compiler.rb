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
      "b80500a20000b80700a20200a1000050a1020050e84180a20400"
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
      "e90000a1000050b8010050e84180c20200b8050050e8ebffa20200a1020050e8e1ffa20400"
  end
end

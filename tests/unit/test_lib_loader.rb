require 'test-unit'
require './utils/converter'
require './compiler/lib_loader'

class TestLibLoader < Test::Unit::TestCase
  def test_satu
    loader = Elang::LibraryFileLoader.new
    functions = loader.load('tests/stdlib.bin')
    assert_equal 2, functions.count
    assert_equal "dos_print_dts", functions[0].name
    assert_equal 0, functions[0].offset
    assert_equal "dos_wait_key", functions[1].name
    assert_equal 18, functions[1].offset
  end
end

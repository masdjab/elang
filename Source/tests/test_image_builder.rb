require 'test-unit'
require './application'
require './function'
require './image_builder'

class TestImageBuilder < Test::Unit::TestCase
  def setup
    puts "TestImageBuilder#setup"
  end
  def teardown
    puts "TestImageBuilder#teardown"
  end
  def test_write_empty_app
    app = Elang::EApplication.new("test")
    builder = Elang::ImageBuilder.new
    assert_equal "", builder.build(app)
  end
  def test_write_functions
    app = Elang::EApplication.new("test")
    fn1 = Elang::EFunction.new("test1")
    fn2 = Elang::EFunction.new("test2")
    fn1.code = "abcde"
    fn2.code = "fghij"
    app.functions << fn1
    app.functions << fn2
    builder = Elang::ImageBuilder.new
    assert_equal "abcdefghij", builder.build(app)
  end
end

require 'test-unit'
require './application'
require './image_builder'

class TestImageBuilder < Test::Unit::TestCase
  def setup
  end
  def teardown
  end
  def test_empty_app
    app = Elang::EApplication.new("test")
    builder = Elang::ImageBuilder.new
    bx_format = builder.build(app)
    
    assert_true bx_format.is_a?(Elang::BXFormat)
    assert_true bx_format.sections.empty?
    assert_equal "BX", bx_format.signature
    assert_true bx_format.raw_image.length > 0
    assert_equal bx_format.header_size, bx_format.raw_image.length
    #assert_true bx_format.checksum != 0
  end
  def test_zero_entry_point
    app = Elang::EApplication.new("test")
    app.main.code = "abc"
    bx_format = Elang::ImageBuilder.new.build(app)
    
    assert_equal 0, bx_format.main_entry_point
    #assert_not_equal 0, bx_format.checksum
    assert_equal 1, bx_format.sections.count
    assert_equal 1, bx_format.sections.select{|x|x.flag == Elang::AppSection::CODE}.count
    assert_equal 0, bx_format.sections.select{|x|x.flag != Elang::AppSection::CODE}.count
  end
  def test_non_zero_entry_point
    app = Elang::EApplication.new("test")
    fn1 = Elang::EFunction.new("test1")
    fn1.code = "abc|"
    app.functions << fn1
    app.main.code = "def"
    bx_format = Elang::ImageBuilder.new.build(app)
    
    assert_equal 4, bx_format.main_entry_point
    #assert_true bx_format.checksum != 0
  end
  def test_constants
  end
  def test_functions
  end
  def test_classes
  end
end

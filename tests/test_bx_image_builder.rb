require 'test-unit'
require './application/application'
require './application/image_builder'
require './application/bx_format'

class TestImageBuilder < Test::Unit::TestCase
  def setup
  end
  def teardown
  end
  def test_empty_app
    app = Elang::EApplication.new
    output = Elang::ImageBuilder.new.build(app, Elang::BXFormat.new)
    
    assert_true output.is_a?(Elang::BXFormat)
    assert_true output.sections.empty?
    assert_equal "BX", output.signature
    assert_true output.raw_image.length > 0
    assert_equal output.header_size, output.raw_image.length
    #assert_true output.checksum != 0
  end
  def test_zero_entry_point
    app = Elang::EApplication.new
    app.main = "abc"
    output = Elang::ImageBuilder.new.build(app, Elang::BXFormat.new)
    
    assert_equal 0, output.main_entry_point
    #assert_not_equal 0, output.checksum
    assert_equal 1, output.sections.count
    assert_equal 1, output.sections.select{|x|x.flag == Elang::AppSection::CODE}.count
    assert_equal 0, output.sections.select{|x|x.flag != Elang::AppSection::CODE}.count
  end
  def test_non_zero_entry_point
    app = Elang::EApplication.new
    app.functions << Elang::EFunction.new(nil, "test1", body: "abc|")
    app.main << "def"
    output = Elang::ImageBuilder.new.build(app, Elang::BXFormat.new)
    
    assert_equal 4, output.main_entry_point
    #assert_true output.checksum != 0
  end
  def test_constants
  end
  def test_variables
  end
  def test_functions
  end
  def test_classes
  end
end

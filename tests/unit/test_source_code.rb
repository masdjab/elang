require 'test-unit'
require './compiler/source_code'

class TestFetcher < Test::Unit::TestCase
  def setup
    @source = <<EOS
puts(3, 5)
puts(_int_pack(2))
d = "COMPUTING"

puts(d.substr(1, 7))
#puts(d.substr(1, 7).substr(2, 5))
d.set_name("Bowo")
EOS
    
    @sc = Elang::StringSourceCode.new(@source.chomp($/))
  end
  def test_detect_lines
    code = <<EOS
row1
row2
row3

EOS
    
    expected = 
      [
        [1, 0, 4], 
        [2, 5, 9], 
        [3, 10, 14], 
        [4, 15, 15]
      ]
    
    assert_equal expected, Elang::StringSourceCode.detect_lines(code).map{|x|[x.row, x.min, x.max]}
  end
  def test_line_at
    assert_equal "puts(3, 5)\n", @sc.line_at(1)
    assert_equal "d = \"COMPUTING\"\n", @sc.line_at(3)
    assert_equal "\n", @sc.line_at(4)
    assert_equal "#puts(d.substr(1, 7).substr(2, 5))\n", @sc.line_at(6)
  end
  def test_highlight
    expected = 
      "1 puts(3, 5)#{$/}" \
      "     ^#{$/}"
    assert_equal expected, @sc.highlight(1, 4, 0)
    
    expected = 
      "1 puts(3, 5)#{$/}" \
      "     ^#{$/}" \
      "2 puts(_int_pack(2))#{$/}"
    assert_equal expected, @sc.highlight(1, 4, 1)
    
    expected = 
      "1 puts(3, 5)#{$/}" \
      "2 puts(_int_pack(2))#{$/}" \
      "     ^#{$/}" \
      "3 d = \"COMPUTING\"#{$/}" \
      "4 #{$/}" \
      "5 puts(d.substr(1, 7))#{$/}"
    assert_equal expected, @sc.highlight(2, 4, 3)
    
    expected = 
      "1 puts(3, 5)#{$/}" \
      "     ^#{$/}" \
      "2 puts(_int_pack(2))#{$/}"
    assert_equal expected, @sc.highlight(1, 4, 1)
    
    expected = 
      "5 puts(d.substr(1, 7))#{$/}" \
      "6 #puts(d.substr(1, 7).substr(2, 5))#{$/}" \
      "7 d.set_name(\"Bowo\")#{$/}" \
      "     ^#{$/}"
    assert_equal expected, @sc.highlight(7, 4, 2)
    
    expected = 
      "5 puts(d.substr(1, 7))#{$/}" \
      "6 #puts(d.substr(1, 7).substr(2, 5))#{$/}" \
      "     ^#{$/}" \
      "7 d.set_name(\"Bowo\")"
    assert_equal expected, @sc.highlight(6, 4, 1)
    
    expected = 
      "puts(3, 5)#{$/}" \
      "   ^#{$/}" \
      "puts(_int_pack(2))#{$/}"
    assert_equal expected, @sc.highlight(1, 4, 1, false)
    
    expected = 
      "1 puts(3, 5)#{$/}" \
      "     ^#{$/}" \
      "2 puts(_int_pack(2))#{$/}"
    assert_equal expected, @sc.highlight(1, 4, 1, 1)
    
    expected = 
      " 1 puts(3, 5)#{$/}" \
      "      ^#{$/}" \
      " 2 puts(_int_pack(2))#{$/}"
    assert_equal expected, @sc.highlight(1, 4, 1, 2)
  end
end

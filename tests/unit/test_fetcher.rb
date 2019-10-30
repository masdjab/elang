require 'test-unit'
require './compiler/fetcher'

class TestFetcher < Test::Unit::TestCase
  IDENTIFIER = "abcdefghijklmnopqrstuvwxyz_"
  
  def test_case_1
    fetcher = Elang::Fetcher.new
    test_code = "text = \"Hello world...\"\r\nputs text\r\n"
    fetcher.init test_code
    assert_equal test_code, fetcher.code
    assert_equal test_code.length, fetcher.code_len
    assert_equal 0, fetcher.char_pos
    assert_equal "", fetcher.fetch{|px, cx|false}
    assert_equal "text", fetcher.fetch{|px, cx|IDENTIFIER.index(cx)}
    assert_equal " = ", (0..2).map{|x|fetcher.fetch}.join
    assert_equal '"', fetcher.fetch
    assert_equal "Hello world...", fetcher.fetch{|px, cx|cx != "\""}
    assert_equal '"', fetcher.fetch
    assert_equal "\r\nputs text\r\n", fetcher.fetch{|px, cx|true}
    assert_equal nil, fetcher.fetch
    assert_equal nil, fetcher.fetch{|px, cx|true}
  end
end

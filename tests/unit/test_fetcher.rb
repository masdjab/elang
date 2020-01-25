require 'test-unit'
require './compiler/fetcher_v2'

class TestFetcher < Test::Unit::TestCase
  IDENTIFIER = "abcdefghijklmnopqrstuvwxyz_"
  
  def test_functionalities
    #(todo)#test all methods: empty? eob?, element, next, prev, last, fetch
    #(todo)#test attributes: items, len, pos
  end
  def test_fetch_string
    test_code = "a+b=215.0"
    fetcher = Elang::FetcherV2.new(test_code)
    assert_equal test_code, fetcher.items
    (0...test_code.length).each{|x|assert_equal test_code[x, 1], fetcher.fetch}
  end
  def test_fetch_array
    #(todo)#test fetch array
  end
end

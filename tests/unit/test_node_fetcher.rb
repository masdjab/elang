require './compiler/exception'
require './compiler/source_code'
require './compiler/fetcher_v2'
require './compiler/node_fetcher'
require './compiler/parser'
require './compiler/lexer'
require './compiler/code_generator'
require 'test-unit'

class TestNodeFetcher < Test::Unit::TestCase
  def create_fetcher(source)
    source  = Elang::StringSourceCode.new(source)
    parser  = Elang::Parser.new
    tokens  = parser.parse(source)
    nodes   = Elang::Lexer.convert_tokens_to_lex_nodes(tokens)
    fetcher = Elang::NodeFetcher.new(nodes)
  end
  def check(source, count = 1, skip_space = true, skip_crlf = false, skip_comment = true)
    fetcher = create_fetcher(source)
    fetcher.check(count, skip_space, skip_crlf, skip_comment)
  end
  def fetch(source, count = 1, skip_space = true, skip_crlf = false, skip_comment = true)
    fetcher = create_fetcher(source)
    fetcher.fetch(count, skip_space, skip_crlf, skip_comment)
  end
  def test_check
    assert_equal "def", check("def").text
    assert_equal "\r\n", check("\r\n\r\n  \t # comment \r\n  def\r\n").text
    assert_equal "def", check("\r\n\r\n  \t # comment \r\n  def\r\n", 1, true, true, true).text
    assert_equal "# comment ", check("\r\n\r\n  \t # comment \r\n  def\r\n", 1, true, true, false).text
    assert_equal "  \t ", check("\r\n\r\n  \t # comment \r\n  def\r\n", 1, false, true, true).text
    assert_equal "def| |end", check("def #comment 1\r\n  \r\nend\r\n", 3, true, true, true).map{|x|x.text}.join("|")
    assert_equal "[]=", check("[]=(index)\r\n", 3).map{|x|x.text}.join
  end
  def test_fetch
    assert_equal "def", fetch("def").text
    assert_equal "\r\n", fetch("\r\n\r\n  \t # comment \r\n  def\r\n").text
    assert_equal "def", fetch("\r\n\r\n  \t # comment \r\n  def\r\n", 1, true, true, true).text
    assert_equal "# comment ", fetch("\r\n\r\n  \t # comment \r\n  def\r\n", 1, true, true, false).text
    assert_equal "  \t ", fetch("\r\n\r\n  \t # comment \r\n  def\r\n", 1, false, true, true).text
    assert_equal "def| |end", fetch("  \t\r\n  def #comment 1\r\n \r\nend\r\n", 3, true, true, true).map{|x|x.text}.join("|")
    assert_equal "[]=", fetch("[]=(index)\r\n", 3).map{|x|x.text}.join
  end
end

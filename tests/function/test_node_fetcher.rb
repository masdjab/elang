require './compiler/source_code'
require './compiler/parser'
require './compiler/lex'
require './compiler/node_fetcher'

source = "  \t\r\n  def #comment 1\r\n \r\nend\r\n"
source = Elang::StringSourceCode.new(source)
parser = Elang::Parser.new
tokens = parser.parse(source)

fetcher = Elang::NodeFetcher.new(tokens)

fetcher.fetch(3, true, true, true).each do |node|
  puts "#{node.type}(#{node.text})"
end

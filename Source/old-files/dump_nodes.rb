require 'parser/current'
require './ast_node_dumper'

Parser::Builders::Default.emit_lambda   = true
Parser::Builders::Default.emit_procarg0 = true
Parser::Builders::Default.emit_encoding = true
Parser::Builders::Default.emit_index    = true

source_file = ARGV[0]
output_file = ARGV[1]
dump_file = File.new(output_file, "w")
items = Parser::CurrentRuby.parse(File.read(source_file))
dumper = AstNodeDumper.new
dumper.dump_nodes(items) do |x|
  puts x
  dump_file.puts x
end
dump_file.close

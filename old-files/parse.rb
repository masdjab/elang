require 'parser/current'
require './compiler'

puts

Parser::Builders::Default.emit_lambda   = true
Parser::Builders::Default.emit_procarg0 = true
Parser::Builders::Default.emit_encoding = true
Parser::Builders::Default.emit_index    = true

source_file = ARGV[0]
output_file = ARGV[1]
source_code = File.read(source_file)
ast_nodes = Parser::CurrentRuby.parse(source_code)
sexp = ast_nodes.to_sexp_array
p sexp.inspect
puts

compiler = Compiler.new
compiler.compile(ast_nodes)
puts File.read(compiler.asm_file)

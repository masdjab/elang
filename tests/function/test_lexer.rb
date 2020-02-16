require './compiler/parser'
require './compiler/lexer'

    source = <<EOS
puts(3, 5)
puts(_int_pack(2))
d = "COMPUTING"
puts(d.substr(3, 5))
d.set_name("Bowo")
EOS

parser = Elang::Parser.new
tokens = parser.parse(source)
ast_nodes = Elang::Lexer.new.to_sexp_array(tokens, parser.code_lines)
puts Elang::Lexer.sexp_display(ast_nodes)

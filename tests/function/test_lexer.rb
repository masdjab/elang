require './compiler/parser'
require './compiler/lexer'

    source = <<EOS
def tambah(a, b)
  a + b
end

a = tambah(4, 3)
EOS

tokens = Elang::Parser.new.parse(source)
ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
puts Elang::Lexer.sexp_display(ast_nodes)

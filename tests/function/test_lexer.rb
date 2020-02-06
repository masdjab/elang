require './compiler/parser'
require './compiler/lexer'

source = <<EOS
class String
end

a = "Hello world..."
b = "This is just a simple text."

puts(a)
EOS

tokens = Elang::Parser.new.parse(source)
ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
puts Elang::Lexer.sexp_display(ast_nodes)

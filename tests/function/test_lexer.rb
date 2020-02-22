require './compiler/exception'
require './compiler/parser'
require './compiler/lexer'

=begin
    source1 = <<EOS
puts(3, 5)
puts(_int_pack(2))
d = "COMPUTING"
puts(d.substr(1, 7))
#puts(d.substr(1, 7).substr(2, 5))
d.set_name("Bowo")
#d.set_name "Bowo"  # parameter without brackets
EOS
    
    sources = 
      [
        "a + b * c - d", 
        "1 + (32 + p)", 
        "x = 1 + (32 + p)", 
        "a.b+c*d.e", 
        "a.b(1)+c*d.e(2)", 
        "a.b(1,2)+c*d.e(3,4)", 
        "a = tambah(4, 3)", 
        "x = p1.get(0).phone.substr(0, 2)", 
        "puts(3, 5)", 
        "puts(_int_pack(2))", 
        "x = 32 + p * 5 - 4 & q * r / s + 1", 
        "x = (32 + p) * (5 - 4) & q * r / s + 1", 
        "x = (32 + p * (5 - sqrt(4))) & (q * r / s + 1)", 
        "x = (32 + p) * (5 - 4) & q * r / s + 1", 
        source1, 
      ]
      
source = sources[12]
tokens = Elang::Parser.new.parse(source)
ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
puts "code: #{source}"
#puts "[[+,[+,a,b],c]]"
puts Elang::Lexer.sexp_display(ast_nodes)
=end

source = <<EOS
a = 2

if a == 2
  puts("a == 2")
#elsif a == 3
#  puts("a == 3")
else
  puts("a != 2")
end
EOS

tokens = Elang::Parser.new.parse(source)
ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
puts "code: #{source}"
puts
puts Elang::Lexer.sexp_display(ast_nodes)

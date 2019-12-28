require './compiler/parser'
require './compiler/lexer'

sources = []
sources << "x = 32 + 5\nputs x\n"
sources << "x = 32 + p * 5 - 4 & q * r / s + 1"
sources << "x = (32 + p) * (5 - 4) & q * r / s + 1"
sources << "x = (32 + p * (5 - sqrt(4))) & (q * r / s + 1)"
sources << <<EOS
# function usage example
def display(info, add_new_line = false)
  puts info
  puts if add_new_line
end
def tcase(text)
  result = ''
  
  each(split(text, ' ')) do |t|
    result = result + ' ' if len(result) > 0
    result = result + ucase(part(t, 0, 1)) + part(t, 1, -1)
  end
  
  result
end

a = "hello world...".tcase
show a
EOS

if false
  source = sources[1]
  puts source.inspect
  puts "[=,x,[+,32,[-,[*,p,5],[+,[/,[*,[&,4,q],r],s],1]]]]"
  tokens = Elang::Parser.new.parse(source)
  ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
  puts Elang::Lexer.sexp_display(ast_nodes)
elsif false
  source = "1 + (32 + p)"
  puts source.inspect
  tokens = Elang::Parser.new.parse(source)
  ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
  puts Elang::Lexer.sexp_display(ast_nodes)
elsif false
  source = sources[2]
  puts source.inspect
  puts "[=,x,[*,[+,32,p],[+,[/,[*,[&,[-,5,4],q],r],s],1]]]"
  tokens = Elang::Parser.new.parse(source)
  ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
  puts Elang::Lexer.sexp_display(ast_nodes)
elsif false
  source = sources[3]
  puts source.inspect
  puts "[=,x,[&,[+,32,[*,p,[-,5,[sqrt,[4]]]]],[*,q,[+,[/,r,s],1]]]]"
  tokens = Elang::Parser.new.parse(source)
  ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
  puts Elang::Lexer.sexp_display(ast_nodes)
elsif false
  source = "x = mid(text, sqrt(2), 4)"
  puts source.inspect
  tokens = Elang::Parser.new.parse(source)
  ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
  puts Elang::Lexer.sexp_display(ast_nodes)
else
  source = "def hitung(text)\r\nx = mid(text, sqrt(2), 4)\r\nend"
  puts source.inspect
  tokens = Elang::Parser.new.parse(source)
  ast_nodes = Elang::Lexer.new.to_sexp_array(tokens)
  puts Elang::Lexer.sexp_display(ast_nodes)
end

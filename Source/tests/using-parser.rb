require 'parser/current'

Parser::Builders::Default.emit_lambda   = true
Parser::Builders::Default.emit_procarg0 = true
Parser::Builders::Default.emit_encoding = true
Parser::Builders::Default.emit_index    = true

e1 = <<EOS
class Person
  attr_accessor :name
  
  def initialize(name)
    @name = name
  end
  def sapa
    puts "Hello #{@name}..."
  end
end
EOS

items = Parser::CurrentRuby.parse(e1)
sexp = items.to_sexp_array
p sexp.inspect

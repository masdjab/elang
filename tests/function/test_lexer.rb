require './compiler/exception'
require './compiler/source_code'
require './compiler/fetcher_v2'
require './compiler/node_fetcher'
require './compiler/parser'
require './compiler/lexer'
require './compiler/code_generator'

#source = "tc.value = kita(sum), vx, 2"
#source = "sum sum sum 2, sum 3, 4"
#source = "p1.set_age 32"
#source = "p1.set_age 32#{$/}puts \"p1.age = \".concat p1.get_age.to_s"
#source = "puts \"tc + 3 = \" + (tc + 3).to_s"

source = <<EOS
class TestClass
  def info(object)
  end
  def empty!
  end
  def empty?
  end
  def name()
  end
  def name=(v)
  end
  def [](index)
  end
  def []=(index, value)
  end
end

t1 = TestClass.new
t1.name = n = "Paijo"
a[x, 2] = a[1, 3] + t.sum 5, 4, (a + 3)
puts("a: " + a.to_s, 5)
puts "5 - 2 = " + (5 - 2).to_s
@name = "Paijo"
@@name = "Paijo"
set(v)            # [send,nil,set,[...]]
set v             # [send,nil,set,[...]]
t1.set(v)         # [send,t1,set,[...]]
t1.empty!
t1.empty?
t1.v = 1          # [send,t1,v=,[...]]
t1.a
t1.a.b.c().d().e
@name.inspect
@@name.inspect
t1[0]             # [send,t1,[],[...]]
t1[0] = 1         # [send,t1,[]=,[...]]
[1, 2, 3, 4, 5]
[a, 2 + 4, 1, "Hello"]
{'a' => 2, 'b' => 1, 'c' => 4}
EOS

#source = <<EOS
#puts(3, 5)
#puts(_int_pack(2))
#d = "COMPUTING"
#puts(d.substr(4, 6))
#EOS
#source = "puts(3, 5)"
#source = "puts \"1 + 1 = \" + a.to_s"
#source = "puts((6 + 3).to_s)"
#source = "x = (32 + p * (5 - sqrt(4))) & (q * r / s + 1)"
#source = "x = (32 + p)"
#source = "1 + 2"
#source = "1 + (32 + p)"
#source = "puts(d.substr(4, 6))"
#source = "if true\r\n  x = 3\r\nend\r\n"
#source = "t1.v = 1\r\n"
#source = "[1, 2, 3, 4, 5]"
#source = "{'one' => 1, 'two' => 2, 'three' => 3, 'four' => 4, 'five' => 5}"
#source = "a = 2 + (3 + 1)"


puts source
puts

source  = Elang::StringSourceCode.new(source)
parser  = Elang::Parser.new
lexer   = Elang::Lexer.new
tokens  = parser.parse(source)
nodes   = lexer.to_sexp_array(tokens, source)

puts Elang::Lexer.sexp_to_s(nodes)
#puts nodes.inspect
#nodes.each{|n|puts n.inspect}

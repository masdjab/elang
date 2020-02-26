require './compiler/exception'
require './compiler/source_code'
require './compiler/parser'
require './compiler/lexer'
require './compiler/code_generator'

source = <<EOS
class TestClass
  def set_value(v)
    @value = v
  end
  def value=(v)
    @value = v
  end
  def value
    @value
  end
  def +(v)
    @value + v
  end
end

tc = TestClass.new
tc.value = 2
tc.set_value(2)
puts((tc + 3).to_s())
EOS

#source = "tc.value = kita(sum), vx, 2"
#source = "sum sum sum 2, sum 3, 4"
#source = "p1.set_age 32"
source = "p1.set_age 32#{$/}puts \"p1.age = \".concat p1.get_age.to_s"
source = "puts \"tc + 3 = \".concat (tc + 3).to_s"
puts source
source  = Elang::StringSourceCode.new(source)
parser  = Elang::Parser.new
lexer   = Elang::Lexer.new
tokens  = parser.parse(source)
nodes   = lexer.to_sexp_array(tokens, source)

puts Elang::Lexer.sexp_display(nodes)

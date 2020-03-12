require 'test-unit'
require './compiler/source_code'
require './compiler/exception'
require './compiler/parser'
require './compiler/lexer'

class TestLexer < Test::Unit::TestCase
  def setup
    @parser = Elang::Parser.new
    @lexer = Elang::Lexer.new
  end
  def check_expression(expression, expected)
    source = Elang::StringSourceCode.new(expression)
    tokens = @parser.parse(source)
    nodes = @lexer.to_sexp_array(tokens)
    display = Elang::Lexer.sexp_to_s(nodes)
    
    if expected.is_a?(Array)
      expected = Elang::Lexer.sexp_to_s(expected)
    end
    
    assert_equal expected, display
  end
  def test_simple_expression
    check_expression "", "[]"
    check_expression "1 + 2", "[[.,1,+,[2]]]"
    check_expression "1 * 2", "[[.,1,*,[2]]]"
    check_expression "a + b", "[[.,a,+,[b]]]"
    check_expression "a + 6", "[[.,a,+,[6]]]"
    check_expression "3 + c", "[[.,3,+,[c]]]"
    check_expression "1 + (32 + p)", "[[.,1,+,[[.,32,+,[p]]]]]"
  end
  def test_medium_expression
    check_expression \
      "a = 1 + 1", 
      "[[.,a,=,[[.,1,+,[1]]]]]"
      
    check_expression \
      "x = 32 + p * 5 - 4 & q * r / s + 1", 
      "[[.,x,=,[[.,[.,[.,32,+,[[.,p,*,[5]]]],-,[4]],&,[[.,[.,[.,q,*,[r]],/,[s]],+,[1]]]]]]]"
    check_expression \
      "x = (32 + p) * (5 - 4) & q * r / s + 1", 
      "[[.,x,=,[[.,[.,[.,32,+,[p]],*,[[.,5,-,[4]]]],&,[[.,[.,[.,q,*,[r]],/,[s]],+,[1]]]]]]]"
    check_expression \
      "x = (32 + p * (5 - sqrt(4))) & (q * r / s + 1)", 
      "[[.,x,=,[[.,[.,32,+,[[.,p,*,[[.,5,-,[[.,nil,sqrt,[4]]]]]]]],&,[[.,[.,[.,q,*,[r]],/,[s]],+,[1]]]]]]]"
    
    check_expression \
      "x = mid(text, sqrt(2), 4)", 
      "[[.,x,=,[[.,nil,mid,[text,[.,nil,sqrt,[2]],4]]]]]"
    
    check_expression \
      "x = 2\r\ny = 3\r\n", 
      "[[.,x,=,[2]],[.,y,=,[3]]]"
    
    check_expression \
      "puts \"1 + 1 = \" + a.to_s", 
      "[[.,nil,puts,[[.,1 + 1 = ,+,[[.,a,to_s,[]]]]]]]"
    
    check_expression \
      "a = 1 + 1#{$/}puts \"1 + 1 = \" + a.to_s", 
      "[[.,a,=,[[.,1,+,[1]]]],[.,nil,puts,[[.,1 + 1 = ,+,[[.,a,to_s,[]]]]]]]"
    
    check_expression \
      "puts \"tc + 3 = \".concat (tc + 3).to_s", 
      "[[.,nil,puts,[[.,tc + 3 = ,concat,[[.,[.,tc,+,[3]],to_s,[]]]]]]]"
    
    check_expression \
      "puts((6 + 3).to_s)", 
      "[[.,nil,puts,[[.,[.,6,+,[3]],to_s,[]]]]]"
    
    check_expression \
      "puts (6 + 3).to_s", 
      "[[.,nil,puts,[[.,[.,6,+,[3]],to_s,[]]]]]"
    
    check_expression \
      "def hitung\r\na = 2\r\nend\r\n", 
      "[[def,nil,hitung,[],[[.,a,=,[2]]]]]"
    
    check_expression \
      "def hitung(text)\r\nx = mid(text, sqrt(2), 4)\r\nend", 
      "[[def,nil,hitung,[text],[[.,x,=,[[.,nil,mid,[text,[.,nil,sqrt,[2]],4]]]]]]]"
    
    check_expression \
      "def hitung(text)\r\nx = mid(text, sqrt(2), 4)\r\nend", 
      [["def",nil,"hitung",["text"],[[".","x","=",[[".",nil,"mid",["text",[".",nil,"sqrt",["2"]],"4"]]]]]]]
    
    check_expression \
      "def <<(v)\r\n@value << v\r\nend\r\n", 
      [["def",nil,"<<",["v"],[[".","@value","<<",["v"]]]]]
    
    check_expression \
      "def >>(v)\r\n@value >> v\r\nend\r\n", 
      [["def",nil,">>",["v"],[[".","@value",">>",["v"]]]]]
    
    check_expression \
      "def [](v)\r\n@value[v]\r\nend\r\n", 
      [["def",nil,"[]",["v"],[[".","@value","[]",["v"]]]]]
    
    check_expression \
      "def []=(i, v)\r\n@value[i] = v\r\nend\r\n", 
      [["def",nil,"[]=",["i","v"],[[".","@value","[]=",["i","v"]]]]]
    
    check_expression \
      "def self.hitung(text)\r\nx = mid(text, sqrt(2), 4)\r\nend", 
      [["def","self","hitung",["text"],[[".","x","=",[[".",nil,"mid",["text",[".",nil,"sqrt",["2"]],"4"]]]]]]]
    
    check_expression \
      "a = [1,2,3]\r\nb = a[1]\r\na[1] = 2\r\n", 
      "[[.,a,=,[[1,2,3]]],[.,b,=,[[.,a,[],[1]]]],[.,a,[]=,[1,2]]]"
    
    check_expression \
      "a = {'a' => 1, 'b' => 2, 'c' => 3}", 
      "[[.,a,=,[[a,1,b,2,c,3]]]]"
  end
  def test_multiline_expression
    #(todo)#fix this bug, caused by \n
    #check_expression "x = 32 + 5\nputs x\n", "[[=,x,[+,32,5]],[.,nil,puts,[x]]"
    
    source = <<EOS
def tambah(a, b)
  a + b
end

a = tambah(4, 3)
EOS
    
    check_expression \
      source, 
      [
        ["def",nil,"tambah",["a","b"],[[".","a","+",["b"]]]], 
        [".","a","=",[[".",nil,"tambah",["4","3"]]]]
      ]
      
      
    source = <<EOS
puts(3, 5)
puts(_int_pack(2))
d = "COMPUTING"
puts(d.substr(4, 6))
EOS
    
    check_expression \
      source, 
      [
        [".",nil,"puts",[3,5]], 
        [".",nil,"puts",[[".",nil,"_int_pack",[2]]]], 
        [".","d","=",["COMPUTING"]], 
        [".",nil,"puts",[[".","d","substr",[4,6]]]]
      ]
  end
  def test_multiline_complex_expression
    source = <<EOS
class String
end

a = "Hello world..."
b = "This is just a simple text."

puts(a)
EOS
    
    check_expression \
      source, 
      [
        ["class","String",nil,[]], 
        [".","a","=",["Hello world..."]], 
        [".","b","=",["This is just a simple text."]], 
        [".",nil,"puts",["a"]]
      ]
    
    
    source = <<EOS
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
  end
  def test_methods
    source = <<EOS
class Integer
  def to_s
    _int_to_s(_int_unpack(8))
  end
end
EOS
    
    check_expression \
      source, 
      [
        [
          "class", "Integer", nil, 
          [
            [
              "def", nil, "to_s", [], 
              [
                [".",nil,"_int_to_s", [[".",nil,"_int_unpack", ["8"]]]]
              ]
            ]
          ]
        ]
      ]
    
    
    source = <<EOS
class Person
  def get_name
    @name
  end
  def set_name(v)
    @name = v
  end
  def self.get_person_name(person)
    person.get_name
  end
  def self.set_person_name(person, name)
    person.set_name(name)
  end
end

def test_person
  p1 = Person.new
  p1.set_name("Bowo")
  a = p1.get_name
  b = Person.set_person_name(p1, "Agus")
  c = Person.get_person_name(p1)
end

test_person
EOS
    
    check_expression \
      source, 
      [
        [
          "class","Person",nil,
            [
              ["def",nil,"get_name",[],["@name"]],
              ["def",nil,"set_name",["v"],[[".","@name","=",["v"]]]],
              ["def","self","get_person_name",["person"],[[".","person","get_name",[]]]],
              ["def","self","set_person_name",["person","name"],[[".","person","set_name",["name"]]]]
            ]
        ], 
        [
          "def",nil,"test_person",[],
          [
            [".","p1","=",[[".","Person","new",[]]]], 
            [".","p1","set_name",["Bowo"]], 
            [".","a","=",[[".","p1","get_name",[]]]], 
            [".","b","=",[[".","Person","set_person_name",["p1","Agus"]]]], 
            [".","c","=",[[".","Person","get_person_name",["p1"]]]]
          ]
        ], 
        "test_person"
      ]
    
    
    check_expression \
      "x = p1.get(0).phone.substr(0, 2)", 
      [
        [".","x","=",[[".",[".",[".","p1","get",["0"]],"phone",[]],"substr",["0", "2"]]]]
      ]
  end
  def test_if
    source = <<EOS
if true
  x = 3
end
EOS
    
    check_expression \
      source, 
      [["if", ["true"], [[".", "x", "=", ["3"]]], nil]]
      
    
    source = <<EOS
a = 2
if a == 2
  x = 3
end
EOS
    
    check_expression \
      source, 
      [
        [".", "a", "=", [2]], 
        ["if", [[".", "a", "==", [2]]], [[".", "x", "=", ["3"]]], nil]
      ]
      
    
    source = <<EOS
a = 2

if a == 2
  puts("a == 2")
else
  puts("a != 2")
end
EOS
    
    check_expression \
      source, 
      [
        [".", "a", "=", [2]], 
        [
          "if", [[".", "a", "==", [2]]],
          [[".", nil, "puts", ["a == 2"]]], 
          [[".", nil, "puts", ["a != 2"]]]
        ]
      ]
      
    
    source = <<EOS
a = 2

if a == 2
  puts("a == 2")
elsif a == 3
  puts("a == 3")
else
  puts("a != 2, a != 3")
end
EOS
    
    check_expression \
      source, 
      [
        [".", "a", "=", [2]], 
        [
          "if", [[".", "a", "==", [2]]], 
          [[".", nil, "puts", ["a == 2"]]], 
          [
            [
              "elsif", [[".", "a", "==", [3]]], 
              [[".", nil, "puts", ["a == 3"]]],
              [[".", nil, "puts", ["a != 2, a != 3"]]]
            ]
          ]
        ]
      ]
  end
  def test_function_name
  end
  def test_array
    check_expression \
      "a = [1, 2, 3]\r\nb = a[0]\r\n", 
      "[[.,a,=,[[1,2,3]]],[.,b,=,[[.,a,[],[0]]]]]"
  end
end

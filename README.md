# Elang
Programming language written by Heryudi Praja (mr_orche@yahoo.com)

## What is Elang?
Elang is a programming language written in Ruby. It has Ruby like syntax, but compiles to native code. Currently, only Windows COM 16-bit format supported. The development of this language is focused mainly for writing operating system in easy way.

## Objectives and Features
- Easy
- Compiler
- Ability to create output file
- System programming
- Intermediate level

## Requirements
Ruby (v2.6+ recommended)

## Compiling and Running Example Codes
To compile an Elang source code from example directory, type:
`ruby elang.rb examples/person.elang`

To run compiled output, type:
`person.com`

## Code Examples
See more in `examples` directory.

### call_function.elang
```
def add(a, b)
  a + b
end

puts "4 + 3 = " + add(4, 3).to_s
```

Output:
4 + 3 = 7

### escape.elang
```
puts "Text \"with\" linefeed\r\n  Second text\r\n  Third text"
puts "Text \"with\" tab\tcharacter"
```

Output:
Text "with" linefeed
  Second text
  Third text
Text "with" tab character

### fn_name.elang
```
class TestClass
  def initialize(value)
    @value = value
  end
  def empty!
    51
  end
  def empty?
    52
  end
  def value
    @value
  end
  def value=(v)
    @value = v
  end
  def +(v)
    @value + v
  end
  def -(v)
    @value - v
  end
  def *(v)
    @value * v
  end
  def /(v)
    @value / v
  end
  def &(v)
    @value & v
  end
  def |(v)
    @value | v
  end
  def <<(v)
    @value * 2
  end
  def >>(v)
    @value / 2
  end
  def [](index)
    #@value[index]
    53
  end
  def []=(index, v)
    #@value[index] = v
    54
  end
end

tc = TestClass.new
tc.value = 5
puts "tc.value = " + tc.value.to_s
puts "tc.empty! = " + tc.empty!.to_s
puts "tc.empty? = " + tc.empty?.to_s
puts "tc + 2 = " + (tc + 2).to_s
puts "tc - 1 = " + (tc - 1).to_s
puts "tc * 2 = " + (tc * 2).to_s
puts "tc / 2 = " + (tc / 2).to_s
puts "tc & 3 = " + (tc & 3).to_s
puts "tc & 6 = " + (tc & 6).to_s
puts "tc | 2 = " + (tc | 2).to_s
puts "tc << 2 = " + (tc << 2).to_s
puts "tc >> 2 = " + (tc >> 2).to_s
puts "tc[2] = " + tc[2].to_s
puts "tc[2] = 3 = " + (tc[2] = 3).to_s
```

Output:
tc.value = 5
tc.empty! = 51
tc.empty? = 52
tc + 2 = 7
tc - 1 = 4
tc * 2 = 10
tc / 2 = 2
tc & 3 = 1
tc & 6 = 4
tc | 2 = 7
tc << 2 = 10
tc >> 2 = 2
tc[2] = 53
tc[2] = 3 = 54

### if1.elang
```
a = 3

puts (a == 2).to_s
puts (a == 3).to_s
puts (a != 2).to_s
puts (a != 3).to_s

if a == 2
  puts "a == 2"
elsif a == 3
  puts "a == 3"
else
  puts "a != 2, a != 3"
end
```

Output:
false
true
true
false
a == 3

### int.elang
```
a = 2800
b = a + 5
puts b.to_s
puts b.to_h
c = 4 + 3
puts c.to_s
puts (6 + 3).to_s
```

Output:
2805
0AF5
7
9

### numeric_operations.elang
```
a = 21 + 3
b = a - 3
c = b / 7
d = c * 2

puts "a = 21 + 3 = " + a.to_s
puts "b = a - 3 = " + b.to_s
puts "c = b / 7 = " + c.to_s
puts "d = c * 2 = " + d.to_s
```

Output:
a = 21 + 3 = 24
b = a - 3 = 21
c = b / 7 = 3
d = c * 2 = 6

### object.elang
```
class NilClass
  def to_s
    "a nil object"
  end
end

class FalseClass
  def to_s
    "a FalseClass object"
  end
end

class TrueClass
  def to_s
    "a TrueClass object"
  end
end

class Person
  def to_s
    "a Person object"
  end
end

class Programmer
  def to_s
    "a Programmer object"
  end
end

puts 1258.to_s
puts nil.to_s
puts false.to_s
puts true.to_s
puts Person.new.to_s
puts Programmer.new.to_s
```

Output:
1258
a nil object
a FalseClass object
a TrueClass object
a Person object
a Programmer object

### person.elang
```
class Person
  def age
    @age
  end
  def age=(age)
    @age = age
  end
end

class Programmer < Person
  def lang
    @lang
  end
  def lang=(lang)
    @lang = lang
  end
end


p1 = Person.new
p1.age = 32
puts "p1.age = " + p1.age.to_s

p2 = Programmer.new
p2.age = 21
p2.lang = "Ruby"
puts "p2.age = " + p2.age.to_s
puts "p2.lang = " + p2.lang
```

Output:
p1.age = 32
p2.age = 21
p2.lang = Ruby

## plus.elang
```
class TestClass
  def value=(v)
    @value = v
  end
  def value
    @value
  end
  def add(v)
    _int_pack(_int_add(_int_unpack(@value), _int_unpack(v)))
  end
  def +(v)
    _int_pack _int_add _int_unpack(@value), _int_unpack v
  end
end

tc = TestClass.new
tc.value = 2
puts "tc.value = " + tc.value.to_s
puts "tc.add(3) = " + tc.add(3).to_s
puts "tc + 3 = " + (tc + 3).to_s
```

Output:
tc.value = 2
tc.add(3) = 5
tc + 3 = 5

### string.elang
```
# test String.concat
puts("* Test String.concat")
a = "Com"
b = "Put"
c = "Ing"
d = a + b + c
puts d
puts ""

# test String.append
puts "* Test String.append"
d = "Com" + b + c
puts d
puts ""

# test String.lcase
puts "* Test lcase"
puts d.lcase
puts ""

# test String.ucase
puts "* Test ucase"
puts d.ucase
puts ""

# test String.substr
puts "* Test substr"
puts "COMPUTING".substr(3, 5)
```

Output:
* Test String.concat
ComPutIng

* Test String.append
ComPutIng

* Test lcase
computing

* Test ucase
COMPUTING

* Test substr
PUTIN

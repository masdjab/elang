class System
  HEAP_OFFSET = 0x200
  HEAP_SIZE   = 0x800
end

def msg(text)
  puts text
end
def method1(a, b)
  a, b = b, a
end

a = "Hello world..."
b = "well..."
msg a
puts "Wello horld..."
method1 a, b

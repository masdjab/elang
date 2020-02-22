class FalseClass
  def to_s
    "false"
  end
end

class TrueClass
  def to_s
    "true"
  end
end

a = 3
b = a == 2
c = a == 3
d = a != 2
e = a != 3

puts(b.to_s)
puts(c.to_s)
puts(d.to_s)
puts(e.to_s)

if a == 2
  puts("a == 2")
elsif a == 3
  puts("a == 3")
else
  puts("a != 2, a != 3")
end

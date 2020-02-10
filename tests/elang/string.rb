class String
  def lcase
    str_lcase(self)
  end
  def ucase
    str_ucase(self)
  end
  def append(str)
    str_append(self, str)
  end
  def substr(pos, len)
    str_substr(self, _int_unpack(pos), _int_unpack(len))
  end
end

# test merge string
puts("* Test merge string")
a = "MisTa"
b = "KeNlY"
c = a.append(b)
puts(c)
puts("")

# test String.substr
puts("* Test substr")
d = c.substr(3, 5)
puts(d)
puts("")

# test String.ucase
puts("* Test ucase")
e = d.ucase
puts(e)
puts("")

# test String.lcase
puts("* Test lcase")
f = e.lcase
puts(f)

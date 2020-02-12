class String
  def lcase
    str_lcase(self)
  end
  def ucase
    str_ucase(self)
  end
  def concat(str)
    str_concat(self, str)
  end
  def append(str)
    str_append(self, str)
  end
  def substr(pos, len)
    str_substr(self, _int_unpack(pos), _int_unpack(len))
  end
end

# test String.concat
puts("* Test String.concat")
a = "Com"
b = "Put"
c = "Ing"
d = a.concat(b)
e = d.concat(c)
puts(e)
puts("")

# test String.append
puts("* Test String.append")
f = "Com"
f.append(b)
f.append(c)
puts(f)
puts("")

# test String.lcase
puts("* Test lcase")
g = f.lcase
puts(g)
puts("")

# test String.ucase
puts("* Test ucase")
h = g.ucase
puts(h)
puts("")

# test String.substr
puts("* Test substr")
i = h.substr(3, 5)
puts(i)
puts("")

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
d = d.concat(c)
puts(d)
puts("")

# test String.append
puts("* Test String.append")
d = "Com"
puts(d.append(b.append(c)))
puts("")

# test String.lcase
puts("* Test lcase")
puts(d.lcase)
puts("")

# test String.ucase
puts("* Test ucase")
puts(d.ucase)
puts("")

# test String.substr
puts("* Test substr")
d = "COMPUTING"
puts(d.substr(3, 5))

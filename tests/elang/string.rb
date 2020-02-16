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
d.append(b)
d.append(c)
puts(d)
puts("")

# test String.lcase
puts("* Test lcase")
d = d.lcase
puts(d)
puts("")

# test String.ucase
puts("* Test ucase")
d = d.ucase
puts(d)
puts("")

# test String.substr
puts("* Test substr")
d = d.substr(3, 5)
puts(d)
puts("")

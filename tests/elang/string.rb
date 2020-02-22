class String
  def lcase
    _str_lcase(self)
  end
  def ucase
    _str_ucase(self)
  end
  def concat(str)
    _str_concat(self, str)
  end
  def append(str)
    _str_append(self, str)
  end
  def substr(pos, len)
    _str_substr(self, _int_unpack(pos), _int_unpack(len))
  end
end

# test String.concat
puts("* Test String.concat")
a = "Com"
b = "Put"
c = "Ing"
d = a.concat(b).concat(c)
puts(d)
puts("")

# test String.append
puts("* Test String.append")
d = "Com"
puts(d.append(b).append(c))
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
puts("COMPUTING".substr(3, 5))

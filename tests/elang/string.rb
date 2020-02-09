class String
  def append(str)
    str_append(first_block, self, str)
  end
  def lcase
    str_lcase(first_block, self)
  end
  def ucase
    str_ucase(first_block, self)
  end
end

#a = "Hello world..."
#puts(a)
#puts("Elang now can print text!!!")

a = "Hello "
b = "world..."
c = a.append(b)
puts(c)

d = c.ucase
puts(d)

e = c.lcase
puts(e)

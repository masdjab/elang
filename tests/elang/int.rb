class Integer
  def to_h
    _int_to_h16(_int_unpack(self))
  end
  def to_s
    _int_to_s(_int_unpack(self))
  end
end

a = 2800
a = a + 5
b = a.to_s
puts(b)
c = a.to_h
puts(c)

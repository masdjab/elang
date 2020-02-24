class Integer
  def to_h
    _int_to_h16(_int_unpack(self))
  end
  def to_s
    _int_to_s(_int_unpack(self))
  end
end

class NilClass
  def to_s
    ""
  end
end

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

class Object
  def to_s
    "Object"
  end
end

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

class Exception
  def to_s
    "Exception"
  end
end

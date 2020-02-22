class Integer
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

class Exception
  def to_s
    "Exception"
  end
end

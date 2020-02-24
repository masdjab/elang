class NilClass
  def to_s
    "a nil object"
  end
end

class FalseClass
  def to_s
    "a FalseClass object"
  end
end

class TrueClass
  def to_s
    "a TrueClass object"
  end
end

class Person
  def to_s
    "a Person object"
  end
end

puts(1.to_s)
puts(nil.to_s)
puts(true.to_s)
puts(false.to_s)
puts(Person.new.to_s())
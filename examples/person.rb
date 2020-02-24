class Person
  def set_age(age)
    @age = age
  end
  def get_age
    @age
  end
end

class Programmer < Person
  def set_lang(lang)
    @lang = lang
  end
  def get_lang
    @lang
  end
end


p1 = Person.new
p1.set_age(32)
a = p1.get_age()
puts("p1.age = ".concat(p1.get_age().to_s()))

p2 = Programmer.new
p2.set_age(21)
p2.set_lang("Ruby")
b = p2.get_lang
puts("p2.age = ".concat(p2.get_age().to_s()))
puts("p2.lang = ".concat(p2.get_lang()))

class Person
  def set_age(age)
    @age = age
  end
  def get_age
    @age
  end
  def set_sex(sex)
    @sex = sex
  end
  def get_sex
    @sex
  end
  def set_deposit(deposit)
    @deposit = deposit
  end
  def get_deposit
    @deposit
  end
end

class Programmer
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

p2 = Programmer.new
p2.set_lang(6)
b = p2.get_lang

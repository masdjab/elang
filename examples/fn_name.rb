class Test
  def initialize(value)
    @value = value
  end
  def value
    @value
  end
  def value=(v)
    @value = v
  end
  def <<(v)
    1
  end
  def [](index)
    #@value[index]
    2
  end
  def []=(index, v)
    #@value[index] = v
    3
  end
  def empty!
    #@value = []
    4
  end
  def empty?
    #@value.empty?
    5
  end
end

#t = Test.new([1, 2, 3])
#puts "initial value: #{t.value.inspect}"
#t.value = [1, 2]
#puts "set value = [1, 2] => new value = #{t.value.inspect}"
#puts "t[0] = #{t[0].inspect}, t[1] = #{t[1].inspect}"
#t.value[0] = 5
#puts "set value[0] = 5 => new value[0] = #{t[0].inspect}"
#puts "empty? => #{t.empty?.inspect}"
#t.empty!
#puts "emptied => empty? = #{t.empty?.inspect}"
